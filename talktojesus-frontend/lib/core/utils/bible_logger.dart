import 'package:flutter/foundation.dart';

/// Logger utility for Bible feature
/// Only logs in debug mode to prevent performance impact in production
class BibleLogger {
  static const bool _enableLogging = kDebugMode;

  static void log(String message) {
    if (_enableLogging) {
      debugPrint(message);
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void warning(String message) {
    if (_enableLogging) {
      debugPrint('⚠️ $message');
    }
  }

  static void info(String message) {
    if (_enableLogging) {
      debugPrint('ℹ️ $message');
    }
  }

  static void success(String message) {
    if (_enableLogging) {
      debugPrint('✅ $message');
    }
  }
}