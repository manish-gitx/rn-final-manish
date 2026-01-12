import 'package:flutter/foundation.dart';
import '../../domain/repositories/audio_player_repository.dart';

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayerRepository _audioPlayerRepository;

  AudioPlayerController(this._audioPlayerRepository) {
    _listenToAudioPlayer();
  }

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 3, seconds: 30);
  String? _errorMessage;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void _listenToAudioPlayer() {
    _audioPlayerRepository.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _audioPlayerRepository.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayerRepository.durationStream.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
  }

  Future<void> togglePlayPause() async {
    try {
      _clearError();
      if (_isPlaying) {
        await _audioPlayerRepository.pause();
      } else {
        await _audioPlayerRepository.play();
      }
    } catch (e) {
      _setError('Failed to toggle play/pause: $e');
    }
  }

  Future<void> seekToPosition(Duration position) async {
    try {
      _clearError();
      await _audioPlayerRepository.seek(position);
    } catch (e) {
      _setError('Failed to seek: $e');
    }
  }

  Future<void> setAudioSource(String url) async {
    try {
      _clearError();
      await _audioPlayerRepository.setUrl(url);
    } catch (e) {
      _setError('Failed to load audio: $e');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _audioPlayerRepository.dispose();
    super.dispose();
  }
}