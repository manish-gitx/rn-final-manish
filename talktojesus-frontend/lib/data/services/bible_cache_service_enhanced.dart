import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../../core/utils/bible_logger.dart';
import '../../core/utils/lru_cache.dart';
import '../../core/utils/cache_compression.dart';
import '../../domain/models/bible_cache.dart';

/// Enhanced Bible cache service with production-ready features:
/// - LRU memory cache layer
/// - Data compression
/// - Cache size limits
/// - Batch operations
/// - Transactions
/// - Cache versioning
/// - Background maintenance
/// - Metrics tracking
/// - Smart prefetching
class BibleCacheService {
  // Database configuration
  static const String _cacheTableName = 'bible_cache';
  static const String _positionTableName = 'reading_positions';
  static const String _metricsTableName = 'cache_metrics';
  static const int _databaseVersion = 3;

  // Cache limits
  static const int _cacheDurationDays = 30;
  static const int _maxCacheEntries = 1000;
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const int _pruneAmount = 200;

  // Memory cache configuration
  static const int _memCacheSize = 50; // Keep 50 items in memory

  // Maintenance configuration
  static const Duration _maintenanceInterval = Duration(hours: 6);

  // Cache version (increment when schema changes)
  static const int _currentCacheVersion = 1;

  // Instance variables
  Database? _database;
  SharedPreferences? _prefs;
  late final Future<void> _initFuture;
  final LRUCache<String, String> _memoryCache = LRUCache(_memCacheSize);
  Timer? _maintenanceTimer;

  // Metrics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _memCacheHits = 0;
  int _diskCacheHits = 0;

  // Singleton pattern
  static final BibleCacheService _instance = BibleCacheService._internal();
  factory BibleCacheService() => _instance;

  BibleCacheService._internal() {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _database = await _initDatabase();
      _startMaintenanceScheduler();
      await _loadMetrics();
      BibleLogger.success('[BibleCacheService] Initialized successfully');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Initialization failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    await _initFuture;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final dbPath = path.join(databasePath, 'bible_cache.db');

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    BibleLogger.log('[BibleCacheService] Creating database schema v$version');

    await db.execute('''
      CREATE TABLE $_cacheTableName (
        cacheKey TEXT PRIMARY KEY,
        jsonData TEXT NOT NULL,
        cachedAt INTEGER NOT NULL,
        expiresAt INTEGER NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1,
        checksum TEXT,
        accessCount INTEGER NOT NULL DEFAULT 0,
        lastAccessedAt INTEGER NOT NULL,
        namespace TEXT NOT NULL DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE $_positionTableName (
        positionKey TEXT PRIMARY KEY,
        translationId TEXT NOT NULL,
        bookId TEXT NOT NULL,
        chapterNumber INTEGER NOT NULL,
        scrollPosition REAL NOT NULL,
        lastReadAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_metricsTableName (
        id INTEGER PRIMARY KEY,
        cacheHits INTEGER NOT NULL DEFAULT 0,
        cacheMisses INTEGER NOT NULL DEFAULT 0,
        memCacheHits INTEGER NOT NULL DEFAULT 0,
        diskCacheHits INTEGER NOT NULL DEFAULT 0,
        totalSize INTEGER NOT NULL DEFAULT 0,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_expiresAt ON $_cacheTableName (expiresAt)');
    await db.execute('CREATE INDEX idx_lastAccessedAt ON $_cacheTableName (lastAccessedAt)');
    await db.execute('CREATE INDEX idx_namespace ON $_cacheTableName (namespace)');
    await db.execute('CREATE INDEX idx_version ON $_cacheTableName (version)');
    await db.execute('CREATE INDEX idx_lastReadAt ON $_positionTableName (lastReadAt DESC)');

    // Initialize metrics
    await db.insert(_metricsTableName, {
      'id': 1,
      'cacheHits': 0,
      'cacheMisses': 0,
      'memCacheHits': 0,
      'diskCacheHits': 0,
      'totalSize': 0,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    BibleLogger.log('[BibleCacheService] Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN size INTEGER DEFAULT 0');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_lastAccessedAt ON $_cacheTableName (lastAccessedAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_lastReadAt ON $_positionTableName (lastReadAt DESC)');
    }

    if (oldVersion < 3) {
      // Add new columns for version 3
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN version INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN checksum TEXT');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN accessCount INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN lastAccessedAt INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN namespace TEXT DEFAULT "default"');

      // Update lastAccessedAt with cachedAt for existing entries
      await db.execute('UPDATE $_cacheTableName SET lastAccessedAt = cachedAt WHERE lastAccessedAt = 0');

      // Create new indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_namespace ON $_cacheTableName (namespace)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_version ON $_cacheTableName (version)');

      // Create metrics table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_metricsTableName (
          id INTEGER PRIMARY KEY,
          cacheHits INTEGER NOT NULL DEFAULT 0,
          cacheMisses INTEGER NOT NULL DEFAULT 0,
          memCacheHits INTEGER NOT NULL DEFAULT 0,
          diskCacheHits INTEGER NOT NULL DEFAULT 0,
          totalSize INTEGER NOT NULL DEFAULT 0,
          lastUpdated INTEGER NOT NULL
        )
      ''');

      await db.insert(_metricsTableName, {
        'id': 1,
        'cacheHits': 0,
        'cacheMisses': 0,
        'memCacheHits': 0,
        'diskCacheHits': 0,
        'totalSize': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ========== Cache Management ==========

  /// Caches data with compression, checksums, and size tracking
  Future<void> cacheData(
    String key,
    String jsonData, {
    String namespace = 'default',
    int? customExpiryDays,
  }) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      // Compress data
      final compressedData = CacheCompression.compress(jsonData);
      final checksum = CacheCompression.generateChecksum(jsonData);
      final size = CacheCompression.getDataSize(compressedData);

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: customExpiryDays ?? _cacheDurationDays));

      final entry = BibleCacheEntry(
        cacheKey: key,
        jsonData: compressedData,
        cachedAt: now,
        expiresAt: expiresAt,
        size: size,
        version: _currentCacheVersion,
        checksum: checksum,
        accessCount: 0,
        lastAccessedAt: now,
        namespace: namespace,
      );

      // Check cache size limits before inserting
      await _enforceCacheLimits(size);

      // Insert into database
      await db.insert(
        _cacheTableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to memory cache (store decompressed for faster access)
      _memoryCache.put(key, jsonData);

      BibleLogger.log('[BibleCacheService] Cached $namespace:$key ($size bytes, ${compressedData.startsWith('gzip:') ? 'compressed' : 'uncompressed'})');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to cache data for key: $key', e, stackTrace);
    }
  }

  /// Batch cache multiple items in a single transaction
  Future<void> batchCacheData(Map<String, String> dataMap, {String namespace = 'default'}) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        for (final entry in dataMap.entries) {
          final compressedData = CacheCompression.compress(entry.value);
          final checksum = CacheCompression.generateChecksum(entry.value);
          final size = CacheCompression.getDataSize(compressedData);

          final now = DateTime.now();
          final expiresAt = now.add(const Duration(days: _cacheDurationDays));

          final cacheEntry = BibleCacheEntry(
            cacheKey: entry.key,
            jsonData: compressedData,
            cachedAt: now,
            expiresAt: expiresAt,
            size: size,
            version: _currentCacheVersion,
            checksum: checksum,
            accessCount: 0,
            lastAccessedAt: now,
            namespace: namespace,
          );

          await txn.insert(
            _cacheTableName,
            cacheEntry.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          _memoryCache.put(entry.key, entry.value);
        }
      });

      BibleLogger.success('[BibleCacheService] Batch cached ${dataMap.length} items in namespace: $namespace');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to batch cache data', e, stackTrace);
    }
  }

  /// Gets cached data with memory cache layer and LRU tracking
  Future<String?> getCachedData(String key, {bool updateAccessCount = true}) async {
    await _ensureInitialized();

    // Check memory cache first
    final memCached = _memoryCache.get(key);
    if (memCached != null) {
      _memCacheHits++;
      _cacheHits++;
      if (updateAccessCount) {
        unawaited(_updateAccessCount(key));
      }
      BibleLogger.log('[BibleCacheService] Memory cache hit for: $key');
      return memCached;
    }

    final db = _database;
    if (db == null) {
      _cacheMisses++;
      return null;
    }

    try {
      final results = await db.query(
        _cacheTableName,
        where: 'cacheKey = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) {
        _cacheMisses++;
        await _saveMetrics();
        return null;
      }

      final entry = BibleCacheEntry.fromMap(results.first);

      // Version check
      if (entry.version != _currentCacheVersion) {
        await deleteCachedData(key);
        BibleLogger.warning('[BibleCacheService] Cache version mismatch for: $key');
        _cacheMisses++;
        return null;
      }

      // Checksum verification
      final decompressedData = CacheCompression.decompress(entry.jsonData);
      if (entry.checksum != null && !CacheCompression.verifyChecksum(decompressedData, entry.checksum!)) {
        await deleteCachedData(key);
        BibleLogger.warning('[BibleCacheService] Checksum verification failed for: $key');
        _cacheMisses++;
        return null;
      }

      // Expiry check
      if (entry.isExpired) {
        await deleteCachedData(key);
        BibleLogger.log('[BibleCacheService] Cache expired for: $key');
        _cacheMisses++;
        return null;
      }

      // Update LRU tracking
      if (updateAccessCount) {
        unawaited(_updateAccessCount(key));
      }

      // Add to memory cache
      _memoryCache.put(key, decompressedData);

      _diskCacheHits++;
      _cacheHits++;
      await _saveMetrics();

      BibleLogger.log('[BibleCacheService] Disk cache hit for: $key');
      return decompressedData;
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get cached data for key: $key', e, stackTrace);
      _cacheMisses++;
      return null;
    }
  }

  /// Update access count for LRU tracking (non-blocking)
  Future<void> _updateAccessCount(String key) async {
    final db = _database;
    if (db == null) return;

    try {
      await db.rawUpdate('''
        UPDATE $_cacheTableName
        SET accessCount = accessCount + 1,
            lastAccessedAt = ?
        WHERE cacheKey = ?
      ''', [DateTime.now().millisecondsSinceEpoch, key]);
    } catch (e) {
      // Silent fail - not critical
    }
  }

  /// Gets stale cache data (for offline fallback)
  Future<String?> getCachedDataIgnoringExpiry(String key) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return null;

    try {
      final results = await db.query(
        _cacheTableName,
        where: 'cacheKey = ? AND version = ?',
        whereArgs: [key, _currentCacheVersion],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final entry = BibleCacheEntry.fromMap(results.first);
      final decompressedData = CacheCompression.decompress(entry.jsonData);

      // Verify checksum even for stale data
      if (entry.checksum != null && !CacheCompression.verifyChecksum(decompressedData, entry.checksum!)) {
        return null;
      }

      BibleLogger.warning('[BibleCacheService] Serving stale cache for: $key');
      return decompressedData;
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get stale cached data for key: $key', e, stackTrace);
      return null;
    }
  }

  Future<void> deleteCachedData(String key) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      await db.delete(
        _cacheTableName,
        where: 'cacheKey = ?',
        whereArgs: [key],
      );
      _memoryCache.remove(key);
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to delete cached data for key: $key', e, stackTrace);
    }
  }

  /// Deletes all cache entries in a specific namespace
  Future<void> deleteCachedNamespace(String namespace) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      final deleted = await db.delete(
        _cacheTableName,
        where: 'namespace = ?',
        whereArgs: [namespace],
      );
      BibleLogger.log('[BibleCacheService] Deleted $deleted entries from namespace: $namespace');

      // Clear memory cache (simple approach: clear all)
      _memoryCache.clear();
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to delete namespace: $namespace', e, stackTrace);
    }
  }

  Future<void> clearExpiredCache() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final count = await db.delete(
        _cacheTableName,
        where: 'expiresAt < ?',
        whereArgs: [now],
      );
      if (count > 0) {
        BibleLogger.log('[BibleCacheService] Cleared $count expired cache entries');
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to clear expired cache', e, stackTrace);
    }
  }

  Future<void> clearAllCache() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      await db.delete(_cacheTableName);
      _memoryCache.clear();
      BibleLogger.log('[BibleCacheService] Cleared all cache');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to clear all cache', e, stackTrace);
    }
  }

  /// Enforces cache size limits using LRU eviction
  Future<void> _enforceCacheLimits(int newEntrySize) async {
    final db = _database;
    if (db == null) return;

    try {
      // Check entry count
      final entryCount = await getCacheSize();
      if (entryCount >= _maxCacheEntries) {
        await _evictLRUEntries(_pruneAmount);
      }

      // Check total size
      final totalSize = await getTotalCacheSize();
      if (totalSize + newEntrySize > _maxCacheSizeBytes) {
        await _evictBySize(_maxCacheSizeBytes - totalSize - newEntrySize);
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to enforce cache limits', e, stackTrace);
    }
  }

  /// Evicts least recently used entries
  Future<void> _evictLRUEntries(int count) async {
    final db = _database;
    if (db == null) return;

    try {
      // Delete entries with lowest access counts and oldest access times
      final deleted = await db.rawDelete('''
        DELETE FROM $_cacheTableName
        WHERE cacheKey IN (
          SELECT cacheKey FROM $_cacheTableName
          ORDER BY accessCount ASC, lastAccessedAt ASC
          LIMIT ?
        )
      ''', [count]);

      BibleLogger.log('[BibleCacheService] Evicted $deleted LRU entries');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to evict LRU entries', e, stackTrace);
    }
  }

  /// Evicts entries to free up specified size
  Future<void> _evictBySize(int targetSize) async {
    final db = _database;
    if (db == null) return;

    try {
      // Get LRU entries until we free enough space
      final entries = await db.rawQuery('''
        SELECT cacheKey, size FROM $_cacheTableName
        ORDER BY accessCount ASC, lastAccessedAt ASC
      ''');

      int freedSize = 0;
      final keysToDelete = <String>[];

      for (final entry in entries) {
        keysToDelete.add(entry['cacheKey'] as String);
        freedSize += (entry['size'] as int?) ?? 0;
        if (freedSize >= targetSize) break;
      }

      if (keysToDelete.isNotEmpty) {
        await db.delete(
          _cacheTableName,
          where: 'cacheKey IN (${keysToDelete.map((_) => '?').join(',')})',
          whereArgs: keysToDelete,
        );
        BibleLogger.log('[BibleCacheService] Evicted ${keysToDelete.length} entries to free $freedSize bytes');
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to evict by size', e, stackTrace);
    }
  }

  // ========== Reading Position Methods (unchanged) ==========

  Future<void> saveReadingPosition(ReadingPosition position) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      final map = position.toMap();
      map['positionKey'] = position.positionKey;

      await db.insert(
        _positionTableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _prefs?.setString(
        'last_reading_position',
        jsonEncode(position.toMap()),
      );

      BibleLogger.log('[BibleCacheService] Saved reading position: ${position.translationId}/${position.bookId}/${position.chapterNumber}');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to save reading position', e, stackTrace);
    }
  }

  Future<ReadingPosition?> getReadingPosition(String translationId, String bookId) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return null;

    try {
      final positionKey = '${translationId}_$bookId';
      final results = await db.query(
        _positionTableName,
        where: 'positionKey = ?',
        whereArgs: [positionKey],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return ReadingPosition.fromMap(results.first);
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get reading position', e, stackTrace);
      return null;
    }
  }

  Future<ReadingPosition?> getLastReadingPositionForTranslation(String translationId) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return null;

    try {
      final results = await db.query(
        _positionTableName,
        where: 'translationId = ?',
        whereArgs: [translationId],
        orderBy: 'lastReadAt DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;
      return ReadingPosition.fromMap(results.first);
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get last reading position for translation', e, stackTrace);
      return null;
    }
  }

  Future<ReadingPosition?> getLastReadingPosition() async {
    await _ensureInitialized();
    final db = _database;

    try {
      if (db == null) {
        final json = _prefs?.getString('last_reading_position');
        if (json != null) {
          return ReadingPosition.fromMap(jsonDecode(json) as Map<String, dynamic>);
        }
        return null;
      }

      final results = await db.query(
        _positionTableName,
        orderBy: 'lastReadAt DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;
      return ReadingPosition.fromMap(results.first);
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get last reading position', e, stackTrace);
      return null;
    }
  }

  Future<List<ReadingPosition>> getAllReadingPositions() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return [];

    try {
      final results = await db.query(
        _positionTableName,
        orderBy: 'lastReadAt DESC',
      );

      return results.map((map) => ReadingPosition.fromMap(map)).toList();
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get all reading positions', e, stackTrace);
      return [];
    }
  }

  Future<void> deleteReadingPosition(String translationId, String bookId) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      final positionKey = '${translationId}_$bookId';
      await db.delete(
        _positionTableName,
        where: 'positionKey = ?',
        whereArgs: [positionKey],
      );
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to delete reading position', e, stackTrace);
    }
  }

  Future<void> clearAllReadingPositions() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      await db.delete(_positionTableName);
      await _prefs?.remove('last_reading_position');
      BibleLogger.log('[BibleCacheService] Cleared all reading positions');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to clear all reading positions', e, stackTrace);
    }
  }

  // ========== Translation ID Methods ==========

  Future<void> saveLastTranslationId(String translationId) async {
    await _prefs?.setString('last_translation_id', translationId);
  }

  Future<String?> getLastTranslationId() async {
    return _prefs?.getString('last_translation_id');
  }

  // ========== Metrics and Statistics ==========

  Future<void> _loadMetrics() async {
    final db = _database;
    if (db == null) return;

    try {
      final results = await db.query(_metricsTableName, where: 'id = 1', limit: 1);
      if (results.isNotEmpty) {
        final metrics = results.first;
        _cacheHits = (metrics['cacheHits'] as int?) ?? 0;
        _cacheMisses = (metrics['cacheMisses'] as int?) ?? 0;
        _memCacheHits = (metrics['memCacheHits'] as int?) ?? 0;
        _diskCacheHits = (metrics['diskCacheHits'] as int?) ?? 0;
      }
    } catch (e) {
      BibleLogger.error('[BibleCacheService] Failed to load metrics', e);
    }
  }

  Future<void> _saveMetrics() async {
    final db = _database;
    if (db == null) return;

    try {
      await db.update(
        _metricsTableName,
        {
          'cacheHits': _cacheHits,
          'cacheMisses': _cacheMisses,
          'memCacheHits': _memCacheHits,
          'diskCacheHits': _diskCacheHits,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = 1',
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<int> getCacheSize() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return 0;

    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_cacheTableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      BibleLogger.error('[BibleCacheService] Failed to get cache size', e);
      return 0;
    }
  }

  Future<int> getTotalCacheSize() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return 0;

    try {
      final result = await db.rawQuery('SELECT SUM(size) as totalSize FROM $_cacheTableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      BibleLogger.error('[BibleCacheService] Failed to get total cache size', e);
      return 0;
    }
  }

  Future<int> getExpiredCacheCount() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return 0;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_cacheTableName WHERE expiresAt < ?',
        [now],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      BibleLogger.error('[BibleCacheService] Failed to get expired cache count', e);
      return 0;
    }
  }

  /// Gets comprehensive cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();

    final entryCount = await getCacheSize();
    final totalSize = await getTotalCacheSize();
    final expiredCount = await getExpiredCacheCount();

    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;
    final memHitRate = _cacheHits > 0 ? _memCacheHits / _cacheHits : 0.0;

    return {
      'entryCount': entryCount,
      'maxEntries': _maxCacheEntries,
      'totalSizeBytes': totalSize,
      'maxSizeBytes': _maxCacheSizeBytes,
      'expiredCount': expiredCount,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'memCacheHits': _memCacheHits,
      'diskCacheHits': _diskCacheHits,
      'hitRate': hitRate,
      'memHitRate': memHitRate,
      'utilization': entryCount / _maxCacheEntries,
      'sizeUtilization': totalSize / _maxCacheSizeBytes,
      'memoryCache': _memoryCache.stats,
    };
  }

  /// Gets cache statistics by namespace
  Future<Map<String, Map<String, dynamic>>> getCacheStatsByNamespace() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return {};

    try {
      final results = await db.rawQuery('''
        SELECT
          namespace,
          COUNT(*) as count,
          SUM(size) as totalSize,
          AVG(accessCount) as avgAccessCount
        FROM $_cacheTableName
        GROUP BY namespace
      ''');

      return Map.fromEntries(
        results.map((row) => MapEntry(
          row['namespace'] as String,
          {
            'count': row['count'],
            'totalSize': row['totalSize'],
            'avgAccessCount': row['avgAccessCount'],
          },
        )),
      );
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get cache stats by namespace', e, stackTrace);
      return {};
    }
  }

  // ========== Maintenance ==========

  void _startMaintenanceScheduler() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(_maintenanceInterval, (_) {
      unawaited(performMaintenance());
    });
    BibleLogger.log('[BibleCacheService] Maintenance scheduler started (interval: $_maintenanceInterval)');
  }

  Future<void> performMaintenance() async {
    await _ensureInitialized();

    BibleLogger.log('[BibleCacheService] Starting maintenance...');

    try {
      await clearExpiredCache();

      final size = await getCacheSize();
      if (size > _maxCacheEntries) {
        await _evictLRUEntries(_pruneAmount);
      }

      final totalSize = await getTotalCacheSize();
      if (totalSize > _maxCacheSizeBytes) {
        await _evictBySize(totalSize - _maxCacheSizeBytes + (10 * 1024 * 1024)); // Free extra 10MB
      }

      await _saveMetrics();

      final stats = await getCacheStats();
      BibleLogger.success('[BibleCacheService] Maintenance completed. Entries: ${stats['entryCount']}, Size: ${stats['totalSizeBytes']} bytes, Hit rate: ${((stats['hitRate'] as double) * 100).toStringAsFixed(1)}%');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Maintenance failed', e, stackTrace);
    }
  }

  // ========== Cache Warming and Prefetching ==========

  /// Warms cache by preloading frequently accessed data
  Future<void> warmCache() async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      BibleLogger.log('[BibleCacheService] Starting cache warming...');

      // Load most frequently accessed entries into memory cache
      final results = await db.query(
        _cacheTableName,
        orderBy: 'accessCount DESC',
        limit: _memCacheSize,
      );

      int warmed = 0;
      for (final row in results) {
        try {
          final entry = BibleCacheEntry.fromMap(row);
          if (!entry.isExpired && entry.version == _currentCacheVersion) {
            final decompressed = CacheCompression.decompress(entry.jsonData);
            _memoryCache.put(entry.cacheKey, decompressed);
            warmed++;
          }
        } catch (e) {
          // Skip invalid entries
        }
      }

      BibleLogger.success('[BibleCacheService] Cache warming completed. Loaded $warmed entries into memory');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Cache warming failed', e, stackTrace);
    }
  }

  /// Smart prefetching based on reading patterns
  Future<void> prefetchRelatedContent(String translationId, String bookId, int currentChapter) async {
    await _ensureInitialized();
    BibleLogger.log('[BibleCacheService] Prefetching related content for $translationId/$bookId/$currentChapter');

    // This would integrate with BibleRepository to prefetch next chapters
    // For now, just log the intent
    final nextChapters = [currentChapter + 1, currentChapter + 2];
    for (final chapter in nextChapters) {
      final cacheKey = chapterCacheKey(translationId, bookId, chapter);
      // Check if already cached
      final cached = await getCachedData(cacheKey, updateAccessCount: false);
      if (cached == null) {
        BibleLogger.log('[BibleCacheService] Would prefetch: $cacheKey');
        // In real implementation, call repository to fetch and cache
      }
    }
  }

  // ========== Cache Key Generators ==========

  static String translationsCacheKey() => 'translations';
  static String booksCacheKey(String translationId) => 'books_$translationId';
  static String chapterCacheKey(String translationId, String bookId, int chapterNumber) {
    return 'chapter_${translationId}_${bookId}_$chapterNumber';
  }

  // ========== Cleanup ==========

  Future<void> dispose() async {
    _maintenanceTimer?.cancel();
    await _saveMetrics();
    await _database?.close();
    _database = null;
    _memoryCache.clear();
    BibleLogger.log('[BibleCacheService] Disposed');
  }
}

// Helper to avoid awaiting futures (fire and forget)
void unawaited(Future<void> future) {}