import 'package:flutter/foundation.dart';

/// Flavor/Environment types
enum Flavor { dev, prod }

/// Flavor configuration for the app
class FlavorConfig {
  static FlavorConfig? _instance;

  final Flavor flavor;
  final String name;
  final String appIdSuffix;
  final String posthogApiKey;
  final String posthogHost;
  final String sentryDsn;
  final bool enableAnalytics;
  final bool enableErrorTracking;
  final bool enableDebugLogging;

  FlavorConfig._({
    required this.flavor,
    required this.name,
    required this.appIdSuffix,
    required this.posthogApiKey,
    required this.posthogHost,
    required this.sentryDsn,
    required this.enableAnalytics,
    required this.enableErrorTracking,
    required this.enableDebugLogging,
  });

  /// Initialize flavor configuration
  static void initialize({
    required Flavor flavor,
    required String name,
    required String appIdSuffix,
    required String posthogApiKey,
    required String posthogHost,
    required String sentryDsn,
    required bool enableAnalytics,
    required bool enableErrorTracking,
    required bool enableDebugLogging,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      name: name,
      appIdSuffix: appIdSuffix,
      posthogApiKey: posthogApiKey,
      posthogHost: posthogHost,
      sentryDsn: sentryDsn,
      enableAnalytics: enableAnalytics,
      enableErrorTracking: enableErrorTracking,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Get current flavor configuration
  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception('FlavorConfig must be initialized before use');
    }
    return _instance!;
  }

  /// Check if configuration is initialized
  static bool get isInitialized => _instance != null;

  // Convenience getters
  bool get isDevelopment => flavor == Flavor.dev;
  bool get isProduction => flavor == Flavor.prod;

  /// Sentry configuration based on flavor
  double get sentryTracesSampleRate => isProduction ? 0.2 : 1.0;
  double get sentryProfilesSampleRate => isProduction ? 0.1 : 1.0;
  double get sentryReplaySessionSampleRate => isProduction ? 0.01 : 0.1;
  double get sentryReplayErrorSampleRate => isProduction ? 0.5 : 1.0;
  bool get sentrySendPii => isDevelopment;

  String get sentryEnvironment => isProduction ? 'production' : 'development';

  /// Validate configuration
  bool get isValid {
    if (isProduction) {
      return posthogApiKey.isNotEmpty && sentryDsn.isNotEmpty;
    }
    return true; // Always valid in development
  }

  /// Log configuration (for debugging)
  void logConfig() {
    if (kDebugMode || enableDebugLogging) {
      debugPrint('🔧 Flavor Configuration:');
      debugPrint('   - Flavor: ${flavor.name.toUpperCase()}');
      debugPrint('   - App Name: $name');
      debugPrint('   - App ID Suffix: ${appIdSuffix.isEmpty ? '(none)' : appIdSuffix}');
      debugPrint('   - PostHog: ${posthogApiKey.isNotEmpty ? 'Configured' : 'Missing'}');
      debugPrint('   - Sentry: ${sentryDsn.isNotEmpty ? 'Configured' : 'Missing'}');
      debugPrint('   - Analytics: ${enableAnalytics ? 'Enabled' : 'Disabled'}');
      debugPrint('   - Error Tracking: ${enableErrorTracking ? 'Enabled' : 'Disabled'}');
      debugPrint('   - Debug Logging: ${enableDebugLogging ? 'Enabled' : 'Disabled'}');
      debugPrint('   - Traces Sample Rate: $sentryTracesSampleRate');
      debugPrint('   - Profiles Sample Rate: $sentryProfilesSampleRate');
      debugPrint('   - Replay Session Sample Rate: $sentryReplaySessionSampleRate');
      debugPrint('   - Send PII: $sentrySendPii');
    }
  }
}