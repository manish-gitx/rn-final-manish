import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/bible_logger.dart';
import '../../domain/models/bible_cache.dart';

class BibleCacheService {
  static const String _cacheTableName = 'bible_cache';
  static const String _positionTableName = 'reading_positions';
  static const int _cacheDurationDays = 30;
  static const int _maxCacheEntries = 1000;
  static const int _pruneAmount = 200;
  static const int _databaseVersion = 4;

  Database? _database;
  SharedPreferences? _prefs;
  late final Future<void> _initFuture;

  static final BibleCacheService _instance = BibleCacheService._internal();
  factory BibleCacheService() => _instance;

  BibleCacheService._internal() {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _database = await _initDatabase();
      BibleLogger.success('[BibleCacheService] Initialized successfully');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// Ensures initialization is complete before proceeding
  Future<void> _ensureInitialized() async {
    await _initFuture;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/bible_cache.db';

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    BibleLogger.log('[BibleCacheService] Creating database schema v$version');

    // Create cache table
    await db.execute('''
      CREATE TABLE $_cacheTableName (
        cacheKey TEXT PRIMARY KEY,
        jsonData TEXT NOT NULL,
        cachedAt INTEGER NOT NULL,
        expiresAt INTEGER NOT NULL,
        size INTEGER DEFAULT 0,
        version INTEGER DEFAULT 1,
        checksum TEXT,
        accessCount INTEGER DEFAULT 0,
        lastAccessedAt INTEGER NOT NULL,
        namespace TEXT DEFAULT 'default'
      )
    ''');

    // Create reading positions table
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

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_expiresAt ON $_cacheTableName (expiresAt)
    ''');

    await db.execute('''
      CREATE INDEX idx_cachedAt ON $_cacheTableName (cachedAt)
    ''');

    await db.execute('''
      CREATE INDEX idx_lastReadAt ON $_positionTableName (lastReadAt DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    BibleLogger.log('[BibleCacheService] Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      // Add size column for cache management
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN size INTEGER DEFAULT 0');

      // Add additional indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cachedAt ON $_cacheTableName (cachedAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_lastReadAt ON $_positionTableName (lastReadAt DESC)');
    }

    if (oldVersion < 3) {
      // Add new cache management columns
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN version INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN checksum TEXT');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN accessCount INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN lastAccessedAt INTEGER DEFAULT ${DateTime.now().millisecondsSinceEpoch}');
      await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN namespace TEXT DEFAULT "default"');

      BibleLogger.log('[BibleCacheService] Added cache management columns for LRU and versioning');
    }

    if (oldVersion < 4) {
      // Fix for databases that were created with incomplete v3 schema
      // Check if columns exist and add them if missing
      final tableInfo = await db.rawQuery('PRAGMA table_info($_cacheTableName)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toSet();

      if (!columnNames.contains('version')) {
        await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN version INTEGER DEFAULT 1');
      }
      if (!columnNames.contains('checksum')) {
        await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN checksum TEXT');
      }
      if (!columnNames.contains('accessCount')) {
        await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN accessCount INTEGER DEFAULT 0');
      }
      if (!columnNames.contains('lastAccessedAt')) {
        await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN lastAccessedAt INTEGER DEFAULT ${DateTime.now().millisecondsSinceEpoch}');
      }
      if (!columnNames.contains('namespace')) {
        await db.execute('ALTER TABLE $_cacheTableName ADD COLUMN namespace TEXT DEFAULT "default"');
      }

      BibleLogger.log('[BibleCacheService] V4 migration completed - ensured all cache columns exist');
    }
  }

  // Cache management methods
  Future<void> cacheData(String key, String jsonData) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return;

    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: _cacheDurationDays));

      final entry = BibleCacheEntry(
        cacheKey: key,
        jsonData: jsonData,
        cachedAt: now,
        expiresAt: expiresAt,
      );

      final entryMap = entry.toMap();
      entryMap['size'] = jsonData.length;

      await db.insert(
        _cacheTableName,
        entryMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      BibleLogger.log('[BibleCacheService] Cached data for key: $key (${jsonData.length} bytes)');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to cache data for key: $key', e, stackTrace);
    }
  }

  Future<String?> getCachedData(String key) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return null;

    try {
      final results = await db.query(
        _cacheTableName,
        where: 'cacheKey = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final entry = BibleCacheEntry.fromMap(results.first);

      // Check if cache is expired
      if (entry.isExpired) {
        await deleteCachedData(key);
        BibleLogger.log('[BibleCacheService] Cache expired for key: $key');
        return null;
      }

      BibleLogger.log('[BibleCacheService] Cache hit for key: $key');
      return entry.jsonData;
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to get cached data for key: $key', e, stackTrace);
      return null;
    }
  }

  /// Gets cached data even if expired (for offline fallback)
  Future<String?> getCachedDataIgnoringExpiry(String key) async {
    await _ensureInitialized();
    final db = _database;
    if (db == null) return null;

    try {
      final results = await db.query(
        _cacheTableName,
        where: 'cacheKey = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final entry = BibleCacheEntry.fromMap(results.first);
      BibleLogger.warning('[BibleCacheService] Serving stale cache for key: $key');
      return entry.jsonData;
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
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to delete cached data for key: $key', e, stackTrace);
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
      BibleLogger.log('[BibleCacheService] Cleared all cache');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Failed to clear all cache', e, stackTrace);
    }
  }

  // Reading position methods
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

      // Also save to SharedPreferences as backup
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
        // Fallback to SharedPreferences
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

  // Last selected translation ID
  Future<void> saveLastTranslationId(String translationId) async {
    await _prefs?.setString('last_translation_id', translationId);
  }

  Future<String?> getLastTranslationId() async {
    return _prefs?.getString('last_translation_id');
  }

  // Cache statistics
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

  // Cleanup and maintenance
  Future<void> performMaintenance() async {
    await _ensureInitialized();

    BibleLogger.log('[BibleCacheService] Starting maintenance...');

    try {
      // Clear expired entries first
      await clearExpiredCache();

      // If cache size exceeds threshold, prune oldest entries
      final size = await getCacheSize();
      if (size > _maxCacheEntries) {
        final db = _database;
        if (db != null) {
          final deleted = await db.rawDelete('''
            DELETE FROM $_cacheTableName
            WHERE cacheKey IN (
              SELECT cacheKey FROM $_cacheTableName
              ORDER BY cachedAt ASC
              LIMIT ?
            )
          ''', [_pruneAmount]);

          BibleLogger.log('[BibleCacheService] Pruned $deleted old cache entries (size was $size)');
        }
      }

      BibleLogger.success('[BibleCacheService] Maintenance completed. Cache size: ${await getCacheSize()}');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleCacheService] Maintenance failed', e, stackTrace);
    }
  }

  // Generate cache keys
  static String translationsCacheKey() => 'translations';
  static String booksCacheKey(String translationId) => 'books_$translationId';
  static String chapterCacheKey(String translationId, String bookId, int chapterNumber) {
    return 'chapter_${translationId}_${bookId}_$chapterNumber';
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}