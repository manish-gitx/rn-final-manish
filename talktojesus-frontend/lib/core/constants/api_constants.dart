class ApiConstants {
  static const String baseUrl =
      'https://e55e415bafa5.ngrok-free.app';

  // Auth endpoints
  static const String createOrGetUser = '/api/auth/create-or-get-user';

  // User endpoints
  static const String getCurrentUser = '/api/user/me';

  // Plans endpoints
  static const String getPlans = '/api/plans';

  // Subscription endpoints
  static const String createSubscription = '/api/subscription/create';
  static const String getCurrentSubscription = '/api/subscription/current';

  // Conversation endpoints
  static const String sendMessage = '/api/conversation/send-message';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
