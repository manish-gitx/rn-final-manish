import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/core/constants/app_strings.dart';
import 'package:talktojesus/core/enums/app_language.dart';

void main() {
  group('AppStrings', () {
    test('every English key has a Telugu translation', () {
      // The bilingual UI is the headline differentiator; this stops the two
      // tables drifting apart as new copy is added.
      expect(
        AppStrings.missingTranslations(AppLanguage.telugu),
        isEmpty,
        reason: 'Add Telugu translations for these keys',
      );
    });

    test('returns the translated string for each language', () {
      expect(AppStrings.get('bible', AppLanguage.english), 'Bible');
      expect(AppStrings.get('bible', AppLanguage.telugu), 'బైబిల్');
    });

    test('English and Telugu values actually differ', () {
      final en = AppStrings.get('sign_out', AppLanguage.english);
      final te = AppStrings.get('sign_out', AppLanguage.telugu);
      expect(en, isNot(equals(te)));
    });

    test('falls back to the key itself for an unknown key', () {
      expect(
        AppStrings.get('definitely_not_a_key', AppLanguage.english),
        'definitely_not_a_key',
      );
    });

    test('getAll returns a non-empty map for both languages', () {
      expect(AppStrings.getAll(AppLanguage.english), isNotEmpty);
      expect(AppStrings.getAll(AppLanguage.telugu), isNotEmpty);
    });

    test('covers the screens used in the demo flow', () {
      const requiredKeys = [
        'login_headline',
        'talk_to_jesus',
        'bible',
        'jesus_songs',
        'conversation_history',
        'subscribe_title',
        'sign_out',
      ];

      for (final key in requiredKeys) {
        expect(
          AppStrings.get(key, AppLanguage.telugu),
          isNot(equals(key)),
          reason: '$key has no Telugu translation',
        );
      }
    });
  });
}
