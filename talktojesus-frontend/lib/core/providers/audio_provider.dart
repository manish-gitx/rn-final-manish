import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AudioState {
  idle,
  loading,
  playing,
  paused,
  error,
}

class AudioPlayerState {
  final AudioState state;
  final double volume;
  final bool isInitialized;
  final String? errorMessage;

  const AudioPlayerState({
    this.state = AudioState.idle,
    this.volume = 0.005,
    this.isInitialized = false,
    this.errorMessage,
  });

  AudioPlayerState copyWith({
    AudioState? state,
    double? volume,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      state: state ?? this.state,
      volume: volume ?? this.volume,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  late AudioPlayer _audioPlayer;

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _audioPlayer = AudioPlayer();
  }

  Future<void> initializeAudio() async {
    state = state.copyWith(state: AudioState.loading);

    try {
      await _audioPlayer.setSource(AssetSource('music/jesus_music.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(state.volume);

      state = state.copyWith(
        state: AudioState.idle,
        isInitialized: true,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      state = state.copyWith(
        state: AudioState.error,
        errorMessage: 'Failed to initialize audio: $e',
      );
    }
  }

  Future<void> play() async {
    if (!state.isInitialized) {
      await initializeAudio();
    }

    if (state.isInitialized) {
      try {
        await _audioPlayer.resume();
        state = state.copyWith(state: AudioState.playing);
      } catch (e) {
        debugPrint('Error playing audio: $e');
        state = state.copyWith(
          state: AudioState.error,
          errorMessage: 'Failed to play audio: $e',
        );
      }
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      state = state.copyWith(state: AudioState.paused);
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      state = state.copyWith(
        state: AudioState.error,
        errorMessage: 'Failed to pause audio: $e',
      );
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      state = state.copyWith(volume: volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> fadeOutAndPause() async {
    if (!state.isInitialized) return;

    final originalVolume = state.volume;
    for (double volume = originalVolume; volume >= 0; volume -= 0.1) {
      await setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await pause();
    await setVolume(originalVolume);
  }

  Future<void> fadeInAndResume() async {
    if (!state.isInitialized) {
      await initializeAudio();
    }

    final targetVolume = state.volume;
    await setVolume(0);
    await play();

    for (double volume = 0; volume <= targetVolume; volume += 0.1) {
      await setVolume(volume.clamp(0, targetVolume));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await setVolume(targetVolume);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});