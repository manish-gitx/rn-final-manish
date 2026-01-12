import '../models/song.dart';

abstract class SongRepository {
  Future<List<Song>> getAllSongs();
  Future<Song?> getSongById(String id);
  Future<List<Song>> searchSongs(String query);
}