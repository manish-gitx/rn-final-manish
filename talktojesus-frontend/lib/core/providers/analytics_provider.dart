import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Provider for PostHog analytics instance
/// This is overridden in main.dart with the initialized instance
final analyticsProvider = Provider<Posthog?>((ref) => null);

/// Analytics service for tracking events
class AnalyticsService {
  final Posthog? _posthog;
  bool _isAvailable = true;

  AnalyticsService(this._posthog) {
    _isAvailable = _posthog != null;
  }

  /// Safely execute PostHog calls with error handling
  Future<void> _safeCall(Future<void> Function() call, String eventName) async {
    if (!_isAvailable || _posthog == null) return;

    try {
      await call();
    } catch (e) {
      _isAvailable = false;
      debugPrint('⚠️ PostHog not available for $eventName: $e');
    }
  }

  // Screen view events
  Future<void> trackScreenView(String screenName) async {
    await _safeCall(() => _posthog!.screen(screenName: screenName), 'screen_view');
  }

  // Jesus Page events
  Future<void> trackJesusImageTap() async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'jesus_image_tapped',
        properties: {'interaction_type': 'image_tap'},
      ),
      'jesus_image_tap',
    );
  }

  Future<void> trackQuestionAsked(String questionLength) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'question_asked',
        properties: {'question_length': questionLength},
      ),
      'question_asked',
    );
  }

  // Audio events
  Future<void> trackAudioSongSelected(String songTitle, int songIndex) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'audio_song_selected',
        properties: {'song_title': songTitle, 'song_index': songIndex},
      ),
      'audio_song_selected',
    );
  }

  Future<void> trackAudioPlayPause(bool isPlaying, String songTitle) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: isPlaying ? 'audio_played' : 'audio_paused',
        properties: {'song_title': songTitle},
      ),
      'audio_play_pause',
    );
  }

  Future<void> trackAudioSkip(String direction, String songTitle) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'audio_skip',
        properties: {'direction': direction, 'song_title': songTitle},
      ),
      'audio_skip',
    );
  }

  Future<void> trackAudioSeek(Duration position, String songTitle) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'audio_seek',
        properties: {'position_seconds': position.inSeconds, 'song_title': songTitle},
      ),
      'audio_seek',
    );
  }

  // Bible events
  Future<void> trackBibleSearch(String searchQuery) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'bible_search',
        properties: {'search_query': searchQuery, 'query_length': searchQuery.length},
      ),
      'bible_search',
    );
  }

  Future<void> trackBibleVerseView(String book, int chapter, int verse) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'bible_verse_viewed',
        properties: {'book': book, 'chapter': chapter, 'verse': verse},
      ),
      'bible_verse_view',
    );
  }

  Future<void> trackBibleBookSelected(String book) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'bible_book_selected',
        properties: {'book': book},
      ),
      'bible_book_selected',
    );
  }

  Future<void> trackBibleChapterSelected(String book, int chapter) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'bible_chapter_selected',
        properties: {'book': book, 'chapter': chapter},
      ),
      'bible_chapter_selected',
    );
  }

  // Navigation events
  Future<void> trackNavigation(String from, String to) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'navigation',
        properties: {'from': from, 'to': to},
      ),
      'navigation',
    );
  }

  // App lifecycle events
  Future<void> trackAppOpened() async {
    await _safeCall(
      () => _posthog!.capture(eventName: 'app_opened'),
      'app_opened',
    );
  }

  Future<void> trackAppBackgrounded() async {
    await _safeCall(
      () => _posthog!.capture(eventName: 'app_backgrounded'),
      'app_backgrounded',
    );
  }

  // Error tracking
  Future<void> trackError(String error, String context) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'error_occurred',
        properties: {'error': error, 'context': context},
      ),
      'error',
    );
  }

  // User properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await _safeCall(
      () => _posthog!.identify(
        userId: properties['user_id']?.toString() ?? 'anonymous',
        userProperties: properties.cast<String, Object>(),
      ),
      'set_user_properties',
    );
  }

  // Feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    await _safeCall(
      () => _posthog!.capture(
        eventName: 'feature_used',
        properties: {'feature_name': featureName},
      ),
      'feature_usage',
    );
  }
}

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final posthog = ref.watch(analyticsProvider);
  return AnalyticsService(posthog);
});