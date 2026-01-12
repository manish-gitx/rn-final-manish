import 'dart:async';
import '../../domain/repositories/audio_player_repository.dart';
import '../../core/constants/audio_player_constants.dart';

class MockAudioPlayerRepository implements AudioPlayerRepository {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  final Duration _totalDuration = AudioPlayerConstants.mockTotalDuration;

  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();

  Timer? _positionTimer;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get totalDuration => _totalDuration;

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playingController.add(_isPlaying);
    _startPositionTimer();
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playingController.add(_isPlaying);
    _stopPositionTimer();
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _playingController.add(_isPlaying);
    _positionController.add(_currentPosition);
    _stopPositionTimer();
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    _positionController.add(_currentPosition);
  }

  @override
  Future<void> setUrl(String url) async {
    _currentPosition = Duration.zero;
    _positionController.add(_currentPosition);
    _durationController.add(_totalDuration);
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && _currentPosition < _totalDuration) {
        _currentPosition += const Duration(seconds: 1);
        _positionController.add(_currentPosition);

        if (_currentPosition >= _totalDuration) {
          pause();
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  void dispose() {
    _stopPositionTimer();
    _playingController.close();
    _positionController.close();
    _durationController.close();
  }
}