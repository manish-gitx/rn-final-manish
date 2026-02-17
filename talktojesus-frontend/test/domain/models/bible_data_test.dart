import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/bible_book.dart';

void main() {
  group('BibleData', () {
    test('books list is not empty', () {
      expect(BibleData.books, isNotEmpty);
    });

    test('Genesis is the first book with 50 chapters', () {
      expect(BibleData.books.first.name, 'Genesis');
      expect(BibleData.books.first.totalChapters, 50);
    });

    test('Psalms has 150 chapters', () {
      final psalms = BibleData.books.firstWhere((b) => b.name == 'Psalms');
      expect(psalms.totalChapters, 150);
    });

    test('all books have positive chapter counts', () {
      for (final book in BibleData.books) {
        expect(book.totalChapters, greaterThan(0),
            reason: '${book.name} should have positive chapters');
      }
    });

    test('versions list contains expected translations', () {
      expect(BibleData.versions, contains('NIV'));
      expect(BibleData.versions, contains('KJV'));
      expect(BibleData.versions, contains('ESV'));
    });

    test('versions list has 6 entries', () {
      expect(BibleData.versions.length, 6);
    });
  });

  group('BibleBook', () {
    test('can be constructed with name and totalChapters', () {
      const book = BibleBook(name: 'Test', totalChapters: 10);
      expect(book.name, 'Test');
      expect(book.totalChapters, 10);
    });
  });
}
