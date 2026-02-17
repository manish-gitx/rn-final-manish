import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/song.dart';

void main() {
  group('Song', () {
    const song = Song(
      id: 'song-1',
      title: 'Amazing Grace',
      duration: '4:30',
      imageUrl: 'https://img.url/cover.jpg',
      audioUrl: 'https://audio.url/song.mp3',
    );

    test('copyWith updates specified fields only', () {
      final updated = song.copyWith(title: 'New Title');

      expect(updated.title, 'New Title');
      expect(updated.id, 'song-1'); // unchanged
      expect(updated.duration, '4:30'); // unchanged
    });

    test('copyWith with no args returns equal copy', () {
      final copy = song.copyWith();
      expect(copy, equals(song));
    });

    test('equality works for identical songs', () {
      const other = Song(
        id: 'song-1',
        title: 'Amazing Grace',
        duration: '4:30',
        imageUrl: 'https://img.url/cover.jpg',
        audioUrl: 'https://audio.url/song.mp3',
      );

      expect(song, equals(other));
    });

    test('equality fails for different songs', () {
      const other = Song(
        id: 'song-2',
        title: 'Amazing Grace',
        duration: '4:30',
      );

      expect(song, isNot(equals(other)));
    });

    test('hashCode is consistent for equal objects', () {
      const other = Song(
        id: 'song-1',
        title: 'Amazing Grace',
        duration: '4:30',
        imageUrl: 'https://img.url/cover.jpg',
        audioUrl: 'https://audio.url/song.mp3',
      );

      expect(song.hashCode, equals(other.hashCode));
    });

    test('toString includes all fields', () {
      final str = song.toString();
      expect(str, contains('song-1'));
      expect(str, contains('Amazing Grace'));
      expect(str, contains('4:30'));
    });

    test('handles null optional fields', () {
      const minimal = Song(id: 'x', title: 'Y', duration: '0:00');
      expect(minimal.imageUrl, isNull);
      expect(minimal.audioUrl, isNull);
    });
  });
}
