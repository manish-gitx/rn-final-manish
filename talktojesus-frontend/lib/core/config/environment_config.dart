import 'package:flutter/foundation.dart';

/// Environment configuration for the app
/// DO NOT commit sensitive values to version control
class EnvironmentConfig {
  // PostHog Configuration
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: kDebugMode ? 'phc_6HuKQBC0LXXvL6nPeXsdM3JUbNexAWKBc7iyOn9YbhK' : '',
  );
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );

  // Sentry Configuration
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: kDebugMode ? 'https://9a8f5dbcb014f55c7077249034fc9ce3@o4510107037728768.ingest.us.sentry.io/4510107039694848' : '',
  );

  // Environment type
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isDevelopment = kDebugMode && !isProduction;

  // Sentry sample rates based on environment
  static double get sentryTracesSampleRate => isProduction ? 0.2 : 1.0;
  static double get sentryProfilesSampleRate => isProduction ? 0.1 : 1.0;
  static double get sentryReplaySessionSampleRate => isProduction ? 0.01 : 0.1;
  static double get sentryReplayErrorSampleRate => isProduction ? 0.5 : 1.0;

  // Privacy settings
  static bool get sentrySendPii => isDevelopment; // Only in dev mode

  // Validate configuration
  static bool get isConfigValid {
    if (isProduction) {
      return posthogApiKey.isNotEmpty && sentryDsn.isNotEmpty;
    }
    return true; // Always valid in development
  }

  // Log configuration status (for debugging)
  static void logConfig() {
    if (kDebugMode) {
      debugPrint('🔧 Environment Configuration:');
      debugPrint('   - Mode: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}');
      debugPrint('   - PostHog: ${posthogApiKey.isNotEmpty ? 'Configured' : 'Missing'}');
      debugPrint('   - Sentry: ${sentryDsn.isNotEmpty ? 'Configured' : 'Missing'}');
      debugPrint('   - Traces Sample Rate: $sentryTracesSampleRate');
      debugPrint('   - Profiles Sample Rate: $sentryProfilesSampleRate');
      debugPrint('   - Replay Session Sample Rate: $sentryReplaySessionSampleRate');
      debugPrint('   - Send PII: $sentrySendPii');
    }
  }
}