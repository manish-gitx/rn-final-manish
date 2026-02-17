import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/core/providers/app_state_provider.dart';
import 'package:talktojesus/core/enums/app_language.dart';

void main() {
  group('AppState', () {
    test('has correct default values', () {
      const state = AppState();

      expect(state.currentLanguage, AppLanguage.english);
      expect(state.isHighContrastMode, isFalse);
      expect(state.audioPermissionGranted, isFalse);
      expect(state.counter, 0);
    });

    test('copyWith updates only specified fields', () {
      const state = AppState();
      final updated = state.copyWith(counter: 5, isHighContrastMode: true);

      expect(updated.counter, 5);
      expect(updated.isHighContrastMode, isTrue);
      expect(updated.currentLanguage, AppLanguage.english); // unchanged
      expect(updated.audioPermissionGranted, isFalse); // unchanged
    });
  });

  group('AppStateNotifier', () {
    late AppStateNotifier notifier;

    setUp(() {
      notifier = AppStateNotifier();
    });

    test('initial state has default values', () {
      expect(notifier.state.currentLanguage, AppLanguage.english);
      expect(notifier.state.counter, 0);
    });

    test('setLanguage updates the language', () {
      notifier.setLanguage(AppLanguage.telugu);
      expect(notifier.state.currentLanguage, AppLanguage.telugu);
    });

    test('toggleHighContrastMode toggles the mode', () {
      expect(notifier.state.isHighContrastMode, isFalse);

      notifier.toggleHighContrastMode();
      expect(notifier.state.isHighContrastMode, isTrue);

      notifier.toggleHighContrastMode();
      expect(notifier.state.isHighContrastMode, isFalse);
    });

    test('setAudioPermission sets the permission flag', () {
      notifier.setAudioPermission(true);
      expect(notifier.state.audioPermissionGranted, isTrue);

      notifier.setAudioPermission(false);
      expect(notifier.state.audioPermissionGranted, isFalse);
    });

    test('incrementCounter increases counter by 1', () {
      notifier.incrementCounter();
      expect(notifier.state.counter, 1);

      notifier.incrementCounter();
      expect(notifier.state.counter, 2);

      notifier.incrementCounter();
      expect(notifier.state.counter, 3);
    });

    test('resetCounter sets counter back to 0', () {
      notifier.incrementCounter();
      notifier.incrementCounter();
      expect(notifier.state.counter, 2);

      notifier.resetCounter();
      expect(notifier.state.counter, 0);
    });
  });

  group('AppLanguage', () {
    test('english has correct code and displayName', () {
      expect(AppLanguage.english.code, 'EN');
      expect(AppLanguage.english.displayName, 'English');
    });

    test('telugu has correct code and displayName', () {
      expect(AppLanguage.telugu.code, 'తె');
      expect(AppLanguage.telugu.displayName, 'Telugu');
    });
  });
}
