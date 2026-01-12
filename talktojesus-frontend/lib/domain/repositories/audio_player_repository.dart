abstract class AudioPlayerRepository {
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get playingStream;

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setUrl(String url);

  bool get isPlaying;
  Duration get currentPosition;
  Duration get totalDuration;

  void dispose();
}