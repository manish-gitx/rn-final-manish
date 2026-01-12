import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';

class MockSongRepository implements SongRepository {
  static const List<Song> _mockSongs = [
    Song(
      id: '1',
      title: 'How Great Thou Art',
      duration: '3:10',
    ),
    Song(
      id: '2',
      title: 'Amazing Grace',
      duration: '4:35',
    ),
    Song(
      id: '3',
      title: 'Be Thou My Vision',
      duration: '3:20',
    ),
    Song(
      id: '4',
      title: 'It Is Well With My Soul',
      duration: '4:15',
    ),
    Song(
      id: '5',
      title: 'Holy, Holy, Holy',
      duration: '3:40',
    ),
    Song(
      id: '6',
      title: 'What a Friend We Have in Jesus',
      duration: '4:05',
    ),
    Song(
      id: '7',
      title: 'How Firm a Foundation',
      duration: '3:55',
    ),
  ];

  @override
  Future<List<Song>> getAllSongs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSongs;
  }

  @override
  Future<Song?> getSongById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockSongs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return _mockSongs;

    return _mockSongs
        .where((song) =>
            song.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}