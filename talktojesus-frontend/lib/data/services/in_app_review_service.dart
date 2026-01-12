import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Configuration
  static const int _minLaunchCount = 5;
  static const int _minDaysSinceInstall = 3;
  static const int _minDaysSinceLastRequest = 15;
  static const int _reviewPromptDelay = 120; // 2 minutes after app start

  // SharedPreferences keys
  static const String _launchCountKey = 'in_app_review_launch_count';
  static const String _installDateKey = 'in_app_review_install_date';
  static const String _lastRequestDateKey = 'in_app_review_last_request_date';

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _incrementLaunchCount();
      await _setInstallDate();
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Failed to initialize InAppReviewService: $e');
      _isInitialized = false;
    }
  }

  Future<void> _incrementLaunchCount() async {
    try {
      if (_prefs == null) return;
      int launchCount = _prefs!.getInt(_launchCountKey) ?? 0;
      await _prefs!.setInt(_launchCountKey, launchCount + 1);
    } catch (e) {
      debugPrint('⚠️ Failed to increment launch count: $e');
    }
  }

  Future<void> _setInstallDate() async {
    try {
      if (_prefs == null) return;
      if (_prefs!.getString(_installDateKey) == null) {
        await _prefs!.setString(_installDateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('⚠️ Failed to set install date: $e');
    }
  }

  Future<void> requestReviewIfAppropriate() async {
    if (!_isInitialized || _prefs == null) {
      debugPrint('⚠️ InAppReviewService not initialized');
      return;
    }

    try {
      if (await _shouldRequestReview()) {
        await _requestReview();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to request review: $e');
    }
  }

  Future<bool> _shouldRequestReview() async {
    try {
      if (_prefs == null) return false;

      final int launchCount = _prefs!.getInt(_launchCountKey) ?? 0;
      final String? installDateStr = _prefs!.getString(_installDateKey);
      final String? lastRequestDateStr = _prefs!.getString(_lastRequestDateKey);

      if (installDateStr == null) {
        return false;
      }

      final DateTime installDate = DateTime.parse(installDateStr);
      final DateTime now = DateTime.now();

      if (launchCount < _minLaunchCount) {
        return false;
      }

      if (now.difference(installDate).inDays < _minDaysSinceInstall) {
        return false;
      }

      if (lastRequestDateStr != null) {
        final DateTime lastRequestDate = DateTime.parse(lastRequestDateStr);
        if (now.difference(lastRequestDate).inDays < _minDaysSinceLastRequest) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Error checking review eligibility: $e');
      return false;
    }
  }

  Future<void> _requestReview() async {
    try {
      if (_prefs == null) return;

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await _prefs!.setString(_lastRequestDateKey, DateTime.now().toIso8601String());
        debugPrint('✅ Review requested successfully');
      } else {
        debugPrint('⚠️ In-app review not available on this device');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to show review prompt: $e');
    }
  }
}
