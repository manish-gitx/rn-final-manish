import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/audio_player_repository.dart';

/// Real playback backed by the `audioplayers` package.
///
/// Accepts either a bundled asset path (`music/hymns/amazing_grace.mp3`) or a
/// remote URL, so the same player works for the offline hymn library and for
/// songs served by the backend.
class AudioPlayersAudioPlayerRepository implements AudioPlayerRepository {
  AudioPlayersAudioPlayerRepository({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _listen();
  }

  final AudioPlayer _player;

  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  void _listen() {
    _subscriptions.addAll([
      _player.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
        _playingController.add(_isPlaying);
      }),
      _player.onPositionChanged.listen((position) {
        _currentPosition = position;
        _positionController.add(position);
      }),
      _player.onDurationChanged.listen((duration) {
        _totalDuration = duration;
        _durationController.add(duration);
      }),
      // Reset to the start so the track can be replayed from the beginning.
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPosition = Duration.zero;
        _playingController.add(false);
        _positionController.add(Duration.zero);
      }),
    ]);
  }

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
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentPosition = Duration.zero;
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setUrl(String url) async {
    if (url.isEmpty) return;

    final source = url.startsWith('http://') || url.startsWith('https://')
        ? UrlSource(url)
        : AssetSource(url);

    await _player.setSource(source);

    // `onDurationChanged` can fire before listeners attach on some platforms,
    // so seed the duration explicitly.
    final duration = await _player.getDuration();
    if (duration != null) {
      _totalDuration = duration;
      _durationController.add(duration);
    }

    _currentPosition = Duration.zero;
    _positionController.add(Duration.zero);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    _playingController.close();
    _positionController.close();
    _durationController.close();
    debugPrint('AudioPlayersAudioPlayerRepository disposed');
  }
}
