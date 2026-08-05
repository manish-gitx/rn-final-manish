import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../services/api_client.dart';

/// Backed by `GET /api/songs` on the Talk to Jesus backend.
///
/// Falls back to an empty list rather than throwing so the songs page can
/// render its empty state instead of an error screen.
class ApiSongRepository implements SongRepository {
  ApiSongRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Song>> getAllSongs() async {
    final response = await _apiClient.getSongs(page: 1, limit: 50);
    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to load songs');
    }
    return response.data ?? const [];
  }

  @override
  Future<Song?> getSongById(String id) async {
    final songs = await getAllSongs();
    for (final song in songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    final response = await _apiClient.getSongs(page: 1, limit: 50, search: query);
    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to search songs');
    }
    return response.data ?? const [];
  }
}
