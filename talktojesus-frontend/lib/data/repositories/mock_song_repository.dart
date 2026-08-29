import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';

/// Offline hymn library bundled with the app.
///
/// Every track is a short excerpt of a Public Domain or CC BY-SA recording
/// sourced from Wikimedia Commons and the Internet Archive — see `assets/music/hymns/ATTRIBUTION.md`
/// for the per-track licence and source URL.
///
/// `audioUrl` is an `audioplayers` asset path, resolved relative to `assets/`.
class MockSongRepository implements SongRepository {
  static const List<Song> _mockSongs = [
    Song(
      id: '1',
      title: 'Amazing Grace',
      duration: '0:42',
      audioUrl: 'music/hymns/amazing_grace.mp3',
      imageUrl: 'assets/images/hymns/amazing_grace.jpg',
    ),
    Song(
      id: '2',
      title: 'The Old Rugged Cross',
      duration: '0:42',
      audioUrl: 'music/hymns/old_rugged_cross.mp3',
      imageUrl: 'assets/images/hymns/old_rugged_cross.jpg',
    ),
    Song(
      id: '3',
      title: 'Be Thou My Vision',
      duration: '0:42',
      audioUrl: 'music/hymns/be_thou_my_vision.mp3',
      imageUrl: 'assets/images/hymns/be_thou_my_vision.jpg',
    ),
    Song(
      id: '4',
      title: 'What a Friend We Have in Jesus',
      duration: '0:42',
      audioUrl: 'music/hymns/what_a_friend.mp3',
      imageUrl: 'assets/images/hymns/what_a_friend.jpg',
    ),
    Song(
      id: '5',
      title: 'Holy, Holy, Holy',
      duration: '0:42',
      audioUrl: 'music/hymns/holy_holy_holy.mp3',
      imageUrl: 'assets/images/hymns/holy_holy_holy.jpg',
    ),
    Song(
      id: '6',
      title: 'Abide With Me',
      duration: '0:30',
      audioUrl: 'music/hymns/abide_with_me.mp3',
      imageUrl: 'assets/images/hymns/abide_with_me.jpg',
    ),
    Song(
      id: '7',
      title: 'Come Thou Fount of Every Blessing',
      duration: '0:42',
      audioUrl: 'music/hymns/come_thou_fount.mp3',
      imageUrl: 'assets/images/hymns/come_thou_fount.jpg',
    ),
    Song(
      id: '8',
      title: 'Rock of Ages',
      duration: '0:42',
      audioUrl: 'music/hymns/rock_of_ages.mp3',
      imageUrl: 'assets/images/hymns/rock_of_ages.jpg',
    ),
    Song(
      id: '9',
      title: 'Nearer, My God, to Thee',
      duration: '0:42',
      audioUrl: 'music/hymns/nearer_my_god.mp3',
      imageUrl: 'assets/images/hymns/nearer_my_god.jpg',
    ),
    Song(
      id: '10',
      title: 'Onward, Christian Soldiers',
      duration: '0:42',
      audioUrl: 'music/hymns/onward_christian_soldiers.mp3',
      imageUrl: 'assets/images/hymns/onward_christian_soldiers.jpg',
    ),
    Song(
      id: '11',
      title: 'Battle Hymn of the Republic',
      duration: '0:42',
      audioUrl: 'music/hymns/battle_hymn.mp3',
      imageUrl: 'assets/images/hymns/battle_hymn.jpg',
    ),
    Song(
      id: '12',
      title: 'Joy to the World',
      duration: '0:42',
      audioUrl: 'music/hymns/joy_to_the_world.mp3',
      imageUrl: 'assets/images/hymns/joy_to_the_world.jpg',
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
