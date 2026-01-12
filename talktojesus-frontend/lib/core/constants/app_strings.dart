import '../enums/app_language.dart';

class AppStrings {
  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      'welcome': 'Welcome',
      'talk_to_jesus': 'Talk to Jesus',
      'prayer_count': 'Prayers',
      'language': 'Language',
      'recording': 'Recording...',
      'listening_to_your_heart': 'Listening to your heart',
      'bible': 'Bible',
    },
    AppLanguage.telugu: {
      'welcome': 'స్వాగతం',
      'talk_to_jesus': 'యేసుతో మాట్లాడండి',
      'prayer_count': 'ప్రార్థనలు',
      'language': 'భాష',
      'recording': 'రికార్డింగ్...',
      'listening_to_your_heart': 'నీ హృదయాన్ని వినిపిస్తున్నావు',
      'bible': 'బైబిల్',
    },
  };

  static String get(String key, AppLanguage language) {
    return _translations[language]?[key] ?? key;
  }

  static Map<String, String> getAll(AppLanguage language) {
    return _translations[language] ?? _translations[AppLanguage.english]!;
  }
}