import '../enums/app_language.dart';

/// App-wide UI copy in English and Telugu.
///
/// Keys are grouped by screen. `get()` falls back to the English string, and
/// then to the key itself, so a missing translation degrades to readable text
/// rather than a blank widget.
class AppStrings {
  static const Map<String, String> _english = {
    // Shared
    'welcome': 'Welcome',
    'talk_to_jesus': 'Talk to Jesus',
    'prayer_count': 'Prayers',
    'language': 'Language',
    'bible': 'Bible',
    'jesus_songs': 'Jesus Songs',
    'cancel': 'Cancel',
    'retry': 'Retry',
    'try_again': 'Try Again',
    'go_home': 'Go Home',
    'loading': 'Loading...',
    'open_settings': 'Open Settings',
    'close': 'Close',
    'something_went_wrong': 'Something went wrong',
    'unexpected_error': 'An unexpected error occurred. Please try again.',

    // Login
    'login_headline': 'God First, Every Day.',
    'login_subtitle': 'Step into His presence, anytime.',
    'sign_up_with_google': 'Sign up with Google',
    'signing_in': 'Signing in...',
    'sign_in_hint': 'Tap to sign up using your Google account',
    'sign_in_success': 'Sign in successful! Welcome.',
    'sign_in_failed': 'Sign in cancelled or failed. Please try again.',
    'demo_account': 'Enter with Demo Account',
    'demo_account_unlocked': 'Demo account unlocked!',

    // Conversation
    'recording': 'Recording...',
    'listening_to_your_heart': 'Listening to your heart',
    'recording_started': 'Recording started',
    'recording_cancelled': 'Recording cancelled',
    'recording_failed': 'Recording failed. Please try again.',
    'recording_start_failed': 'Failed to start recording. Please try again.',
    'send_failed': 'Failed to send message',
    'ask_anything': 'Ask everything and beyond...',
    'send': 'Send',

    // Microphone permissions
    'mic_permission_required': 'Microphone Permission Required',
    'mic_permission_denied': 'Microphone Permission Denied',
    'mic_access_restricted': 'Microphone Access Restricted',

    // Profile / sidebar
    'profile': 'Profile',
    'sign_out': 'Sign Out',
    'conversation_history': 'Conversation History',
    'admin_console': 'Admin Console',

    // History
    'history_empty': 'No conversations yet. Talk to Jesus to begin.',
    'history_failed': 'Could not load your history. Pull down to retry.',
    'you_said': 'You',
    'jesus_said': 'Jesus',

    // Bible
    'my_bible': 'My Bible',
    'select_book_chapter': 'Select Book & Chapter',
    'search_books': 'Search books...',
    'search_translations': 'Search translations...',
    'no_books_found': 'No books found',
    'no_books_available': 'No books available',
    'no_translations_found': 'No translations found',
    'select_translation_hint': 'Select a translation and book to begin reading',
    'chapters': 'chapters',

    // Songs
    'no_songs': 'No songs yet. Pull down to refresh.',
    'songs_failed': 'Could not load songs. Pull down to retry.',

    // Subscription
    'subscribe_title': 'Subscribe to Talk to Jesus',
    'subscription_required': 'Subscription required',
    'no_plans_available': 'No plans available',
    'plans_failed': 'Failed to load plans',
    'login_to_subscribe': 'Please login to subscribe',

    // Connectivity
    'offline': 'You are currently offline',
    'offline_mode': 'Offline mode',
    'no_internet': 'No Internet Connection',
    'no_internet_available': 'No internet connection available',
  };

  static const Map<String, String> _telugu = {
    // Shared
    'welcome': 'స్వాగతం',
    'talk_to_jesus': 'యేసుతో మాట్లాడండి',
    'prayer_count': 'ప్రార్థనలు',
    'language': 'భాష',
    'bible': 'బైబిల్',
    'jesus_songs': 'యేసు పాటలు',
    'cancel': 'రద్దు చేయి',
    'retry': 'మళ్ళీ ప్రయత్నించు',
    'try_again': 'మళ్ళీ ప్రయత్నించండి',
    'go_home': 'హోమ్‌కి వెళ్ళు',
    'loading': 'లోడ్ అవుతోంది...',
    'open_settings': 'సెట్టింగ్‌లు తెరవండి',
    'close': 'మూసివేయి',
    'something_went_wrong': 'ఏదో తప్పు జరిగింది',
    'unexpected_error': 'ఊహించని లోపం సంభవించింది. దయచేసి మళ్ళీ ప్రయత్నించండి.',

    // Login
    'login_headline': 'ప్రతిరోజూ దేవుడే మొదటిది.',
    'login_subtitle': 'ఎప్పుడైనా ఆయన సన్నిధిలోకి రండి.',
    'sign_up_with_google': 'గూగుల్‌తో సైన్ అప్ చేయండి',
    'signing_in': 'సైన్ ఇన్ అవుతోంది...',
    'sign_in_hint': 'మీ గూగుల్ ఖాతాతో సైన్ అప్ చేయడానికి నొక్కండి',
    'sign_in_success': 'సైన్ ఇన్ విజయవంతమైంది! స్వాగతం.',
    'sign_in_failed': 'సైన్ ఇన్ రద్దయింది లేదా విఫలమైంది. మళ్ళీ ప్రయత్నించండి.',
    'demo_account': 'డెమో ఖాతాతో ప్రవేశించండి',
    'demo_account_unlocked': 'డెమో ఖాతా అన్‌లాక్ అయింది!',

    // Conversation
    'recording': 'రికార్డింగ్...',
    'listening_to_your_heart': 'నీ హృదయాన్ని వినిపిస్తున్నావు',
    'recording_started': 'రికార్డింగ్ ప్రారంభమైంది',
    'recording_cancelled': 'రికార్డింగ్ రద్దయింది',
    'recording_failed': 'రికార్డింగ్ విఫలమైంది. మళ్ళీ ప్రయత్నించండి.',
    'recording_start_failed': 'రికార్డింగ్ ప్రారంభించడం విఫలమైంది. మళ్ళీ ప్రయత్నించండి.',
    'send_failed': 'సందేశం పంపడం విఫలమైంది',
    'ask_anything': 'ఏదైనా అడగండి...',
    'send': 'పంపు',

    // Microphone permissions
    'mic_permission_required': 'మైక్రోఫోన్ అనుమతి అవసరం',
    'mic_permission_denied': 'మైక్రోఫోన్ అనుమతి నిరాకరించబడింది',
    'mic_access_restricted': 'మైక్రోఫోన్ ప్రాప్యత పరిమితం',

    // Profile / sidebar
    'profile': 'ప్రొఫైల్',
    'sign_out': 'సైన్ అవుట్',
    'conversation_history': 'సంభాషణ చరిత్ర',
    'admin_console': 'అడ్మిన్ కన్సోల్',

    // History
    'history_empty': 'ఇంకా సంభాషణలు లేవు. యేసుతో మాట్లాడటం ప్రారంభించండి.',
    'history_failed': 'మీ చరిత్రను లోడ్ చేయలేకపోయాము. మళ్ళీ ప్రయత్నించండి.',
    'you_said': 'మీరు',
    'jesus_said': 'యేసు',

    // Bible
    'my_bible': 'నా బైబిల్',
    'select_book_chapter': 'పుస్తకం & అధ్యాయం ఎంచుకోండి',
    'search_books': 'పుస్తకాలను వెతకండి...',
    'search_translations': 'అనువాదాలను వెతకండి...',
    'no_books_found': 'పుస్తకాలు కనబడలేదు',
    'no_books_available': 'పుస్తకాలు అందుబాటులో లేవు',
    'no_translations_found': 'అనువాదాలు కనబడలేదు',
    'select_translation_hint': 'చదవడం ప్రారంభించడానికి అనువాదం మరియు పుస్తకం ఎంచుకోండి',
    'chapters': 'అధ్యాయాలు',

    // Songs
    'no_songs': 'ఇంకా పాటలు లేవు. రిఫ్రెష్ చేయడానికి క్రిందికి లాగండి.',
    'songs_failed': 'పాటలను లోడ్ చేయలేకపోయాము. మళ్ళీ ప్రయత్నించండి.',

    // Subscription
    'subscribe_title': 'యేసుతో మాట్లాడటానికి సబ్‌స్క్రైబ్ చేయండి',
    'subscription_required': 'సబ్‌స్క్రిప్షన్ అవసరం',
    'no_plans_available': 'ప్లాన్‌లు అందుబాటులో లేవు',
    'plans_failed': 'ప్లాన్‌లను లోడ్ చేయడం విఫలమైంది',
    'login_to_subscribe': 'సబ్‌స్క్రైబ్ చేయడానికి దయచేసి లాగిన్ అవ్వండి',

    // Connectivity
    'offline': 'మీరు ప్రస్తుతం ఆఫ్‌లైన్‌లో ఉన్నారు',
    'offline_mode': 'ఆఫ్‌లైన్ మోడ్',
    'no_internet': 'ఇంటర్నెట్ కనెక్షన్ లేదు',
    'no_internet_available': 'ఇంటర్నెట్ కనెక్షన్ అందుబాటులో లేదు',
  };

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: _english,
    AppLanguage.telugu: _telugu,
  };

  /// Falls back to English, then to the key itself, so a missing translation is
  /// visible but never renders as an empty string.
  static String get(String key, AppLanguage language) {
    return _translations[language]?[key] ?? _english[key] ?? key;
  }

  static Map<String, String> getAll(AppLanguage language) {
    return _translations[language] ?? _english;
  }

  /// Keys present in English but missing a Telugu translation. Used by tests to
  /// stop the two tables drifting apart.
  static List<String> missingTranslations(AppLanguage language) {
    final target = _translations[language] ?? const <String, String>{};
    return _english.keys.where((key) => !target.containsKey(key)).toList();
  }
}
