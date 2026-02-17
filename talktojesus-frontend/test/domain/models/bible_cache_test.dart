import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/bible_cache.dart';

void main() {
  group('BibleCacheEntry', () {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 30));
    final pastDate = now.subtract(const Duration(days: 1));

    BibleCacheEntry makeEntry({DateTime? expiresAt, int accessCount = 0}) {
      return BibleCacheEntry(
        cacheKey: 'test-key',
        jsonData: '{"data": "test"}',
        cachedAt: now,
        expiresAt: expiresAt ?? futureDate,
        size: 100,
        version: 2,
        checksum: 'abc123',
        accessCount: accessCount,
        namespace: 'chapters',
      );
    }

    test('toMap/fromMap round-trip preserves all fields', () {
      final entry = makeEntry();
      final map = entry.toMap();
      final restored = BibleCacheEntry.fromMap(map);

      expect(restored.cacheKey, entry.cacheKey);
      expect(restored.jsonData, entry.jsonData);
      expect(restored.size, 100);
      expect(restored.version, 2);
      expect(restored.checksum, 'abc123');
      expect(restored.accessCount, 0);
      expect(restored.namespace, 'chapters');
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = {
        'cacheKey': 'k',
        'jsonData': '{}',
        'cachedAt': now.millisecondsSinceEpoch,
        'expiresAt': futureDate.millisecondsSinceEpoch,
      };

      final entry = BibleCacheEntry.fromMap(map);

      expect(entry.size, 0);
      expect(entry.version, 1);
      expect(entry.checksum, isNull);
      expect(entry.accessCount, 0);
      expect(entry.namespace, 'default');
    });

    test('isExpired returns false for future expiry', () {
      final entry = makeEntry(expiresAt: futureDate);
      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final entry = makeEntry(expiresAt: pastDate);
      expect(entry.isExpired, isTrue);
    });

    test('copyWithAccess increments access count', () {
      final entry = makeEntry(accessCount: 5);
      final accessed = entry.copyWithAccess();

      expect(accessed.accessCount, 6);
      expect(accessed.cacheKey, entry.cacheKey); // unchanged
      expect(accessed.jsonData, entry.jsonData); // unchanged
    });

    test('copyWith updates only specified fields', () {
      final entry = makeEntry();
      final updated = entry.copyWith(version: 3, namespace: 'translations');

      expect(updated.version, 3);
      expect(updated.namespace, 'translations');
      expect(updated.cacheKey, entry.cacheKey); // unchanged
    });
  });

  group('ReadingPosition', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      final position = ReadingPosition(
        translationId: 'kjv',
        bookId: 'GEN',
        chapterNumber: 3,
        scrollPosition: 150.5,
        lastReadAt: DateTime(2025, 6, 15),
      );

      final map = position.toMap();
      final restored = ReadingPosition.fromMap(map);

      expect(restored.translationId, 'kjv');
      expect(restored.bookId, 'GEN');
      expect(restored.chapterNumber, 3);
      expect(restored.scrollPosition, 150.5);
      expect(restored.lastReadAt, DateTime(2025, 6, 15));
    });

    test('positionKey combines translationId and bookId', () {
      final position = ReadingPosition(
        translationId: 'niv',
        bookId: 'PSA',
        chapterNumber: 23,
        scrollPosition: 0,
        lastReadAt: DateTime.now(),
      );

      expect(position.positionKey, 'niv_PSA');
    });
  });
}
