class ApiConstants {
  // Override at build/run time with:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:4040
  // Defaults to the deployed Cloud Run backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://talktojesus-backend-991463842119.us-central1.run.app',
  );

  // Auth endpoints
  static const String createOrGetUser = '/api/auth/create-or-get-user';

  // User endpoints
  static const String getCurrentUser = '/api/user/me';

  // Plans endpoints
  static const String getPlans = '/api/plans';

  // Subscription endpoints
  static const String createSubscription = '/api/subscription/create';
  static const String getCurrentSubscription = '/api/subscription/current';

  // Songs endpoints
  static const String getSongs = '/api/songs';

  // Conversation endpoints
  static const String sendMessage = '/api/conversation/send-message';
  static const String sendTextMessage = '/api/conversation/send-text';
  static const String conversationHistory = '/api/conversation/history';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
