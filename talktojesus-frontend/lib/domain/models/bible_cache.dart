class BibleCacheEntry {
  final String cacheKey;
  final String jsonData;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final int size; // Size in bytes
  final int version; // API/Schema version
  final String? checksum; // Data integrity checksum
  final int accessCount; // Number of times accessed (for LRU)
  final DateTime lastAccessedAt; // Last access time (for LRU)
  final String namespace; // Cache key namespace (translations, books, chapters)

  BibleCacheEntry({
    required this.cacheKey,
    required this.jsonData,
    required this.cachedAt,
    required this.expiresAt,
    this.size = 0,
    this.version = 1,
    this.checksum,
    this.accessCount = 0,
    DateTime? lastAccessedAt,
    this.namespace = 'default',
  }) : lastAccessedAt = lastAccessedAt ?? cachedAt;

  Map<String, dynamic> toMap() {
    return {
      'cacheKey': cacheKey,
      'jsonData': jsonData,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'size': size,
      'version': version,
      'checksum': checksum,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'namespace': namespace,
    };
  }

  factory BibleCacheEntry.fromMap(Map<String, dynamic> map) {
    return BibleCacheEntry(
      cacheKey: map['cacheKey'] as String,
      jsonData: map['jsonData'] as String,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      size: (map['size'] as int?) ?? 0,
      version: (map['version'] as int?) ?? 1,
      checksum: map['checksum'] as String?,
      accessCount: (map['accessCount'] as int?) ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'] as int)
          : DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
      namespace: (map['namespace'] as String?) ?? 'default',
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Creates a copy with updated access information
  BibleCacheEntry copyWithAccess() {
    return BibleCacheEntry(
      cacheKey: cacheKey,
      jsonData: jsonData,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
      size: size,
      version: version,
      checksum: checksum,
      accessCount: accessCount + 1,
      lastAccessedAt: DateTime.now(),
      namespace: namespace,
    );
  }

  /// Creates a copy with specific fields updated
  BibleCacheEntry copyWith({
    String? cacheKey,
    String? jsonData,
    DateTime? cachedAt,
    DateTime? expiresAt,
    int? size,
    int? version,
    String? checksum,
    int? accessCount,
    DateTime? lastAccessedAt,
    String? namespace,
  }) {
    return BibleCacheEntry(
      cacheKey: cacheKey ?? this.cacheKey,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      size: size ?? this.size,
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      namespace: namespace ?? this.namespace,
    );
  }
}

class ReadingPosition {
  final String translationId;
  final String bookId;
  final int chapterNumber;
  final double scrollPosition;
  final DateTime lastReadAt;

  ReadingPosition({
    required this.translationId,
    required this.bookId,
    required this.chapterNumber,
    required this.scrollPosition,
    required this.lastReadAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'translationId': translationId,
      'bookId': bookId,
      'chapterNumber': chapterNumber,
      'scrollPosition': scrollPosition,
      'lastReadAt': lastReadAt.millisecondsSinceEpoch,
    };
  }

  factory ReadingPosition.fromMap(Map<String, dynamic> map) {
    return ReadingPosition(
      translationId: map['translationId'] as String,
      bookId: map['bookId'] as String,
      chapterNumber: map['chapterNumber'] as int,
      scrollPosition: map['scrollPosition'] as double,
      lastReadAt: DateTime.fromMillisecondsSinceEpoch(map['lastReadAt'] as int),
    );
  }

  String get positionKey => '${translationId}_$bookId';
}