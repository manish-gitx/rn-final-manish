import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/app_language.dart';

class AppState {
  final AppLanguage currentLanguage;
  final bool isHighContrastMode;
  final bool audioPermissionGranted;
  final int counter;

  const AppState({
    this.currentLanguage = AppLanguage.english,
    this.isHighContrastMode = false,
    this.audioPermissionGranted = false,
    this.counter = 0,
  });

  AppState copyWith({
    AppLanguage? currentLanguage,
    bool? isHighContrastMode,
    bool? audioPermissionGranted,
    int? counter,
  }) {
    return AppState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      isHighContrastMode: isHighContrastMode ?? this.isHighContrastMode,
      audioPermissionGranted: audioPermissionGranted ?? this.audioPermissionGranted,
      counter: counter ?? this.counter,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setLanguage(AppLanguage language) {
    state = state.copyWith(currentLanguage: language);
  }

  void toggleHighContrastMode() {
    state = state.copyWith(isHighContrastMode: !state.isHighContrastMode);
  }

  void setAudioPermission(bool granted) {
    state = state.copyWith(audioPermissionGranted: granted);
  }

  void incrementCounter() {
    state = state.copyWith(counter: state.counter + 1);
  }

  void resetCounter() {
    state = state.copyWith(counter: 0);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});