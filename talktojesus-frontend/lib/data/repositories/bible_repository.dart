import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/utils/bible_logger.dart';
import '../../domain/models/bible_translation.dart';
import '../services/bible_cache_service.dart';

class BibleRepository {
  static const String baseUrl = 'https://bible.helloao.org/api';
  static const Duration _networkTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  final BibleCacheService _cacheService;
  final http.Client _httpClient;

  BibleRepository(this._cacheService, [http.Client? httpClient])
      : _httpClient = httpClient ?? http.Client();

  /// Check if device has internet connectivity
  Future<bool> _hasConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return connectivity.first != ConnectivityResult.none;
    } catch (e) {
      BibleLogger.warning('[BibleRepository] Connectivity check failed: $e');
      return true; // Assume connectivity if check fails
    }
  }

  /// Make HTTP request with timeout and retry logic
  Future<http.Response> _makeRequest(
    String url, {
    int retryCount = 0,
  }) async {
    try {
      BibleLogger.log('[BibleRepository] Making request to: $url (attempt ${retryCount + 1}/$_maxRetries)');

      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        return response;
      }

      // Retry on server errors (5xx)
      if (response.statusCode >= 500 && retryCount < _maxRetries - 1) {
        final delay = _initialRetryDelay * (retryCount + 1);
        BibleLogger.warning('[BibleRepository] Server error ${response.statusCode}, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return _makeRequest(url, retryCount: retryCount + 1);
      }

      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    } on TimeoutException {
      if (retryCount < _maxRetries - 1) {
        final delay = _initialRetryDelay * (retryCount + 1);
        BibleLogger.warning('[BibleRepository] Request timeout, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      throw TimeoutException('Request timed out after ${_networkTimeout.inSeconds}s');
    } catch (e) {
      if (retryCount < _maxRetries - 1) {
        final delay = _initialRetryDelay * (retryCount + 1);
        BibleLogger.warning('[BibleRepository] Request failed: $e, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return _makeRequest(url, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<List<BibleTranslation>> getAvailableTranslations() async {
    BibleLogger.log('[BibleRepository] Fetching available translations...');

    final cacheKey = BibleCacheService.translationsCacheKey();

    // Try cache first (offline-first strategy)
    final cachedData = await _cacheService.getCachedData(cacheKey);
    if (cachedData != null) {
      BibleLogger.log('[BibleRepository] Loading translations from cache');
      try {
        final translations = await compute(_parseTranslations, cachedData);
        return _sortTranslations(translations);
      } catch (e) {
        BibleLogger.warning('[BibleRepository] Failed to parse cached translations: $e');
      }
    }

    // Check connectivity before attempting network request
    final hasConnectivity = await _hasConnectivity();
    if (!hasConnectivity) {
      BibleLogger.warning('[BibleRepository] No connectivity, checking for stale cache...');
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        try {
          final translations = await compute(_parseTranslations, staleCache);
          return _sortTranslations(translations);
        } catch (e) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cached translations', e);
        }
      }
      throw Exception('No internet connection and no cached data available');
    }

    // Fetch from network
    try {
      final url = '$baseUrl/available_translations.json';
      final response = await _makeRequest(url);

      // Cache the response
      await _cacheService.cacheData(cacheKey, response.body);

      // Parse in isolate
      final translations = await compute(_parseTranslations, response.body);
      BibleLogger.success('[BibleRepository] Loaded ${translations.length} translations from network');

      return _sortTranslations(translations);
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleRepository] Network request failed', e, stackTrace);

      // Last resort: try stale cache
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        BibleLogger.warning('[BibleRepository] Serving stale cache due to network error');
        try {
          final translations = await compute(_parseTranslations, staleCache);
          return _sortTranslations(translations);
        } catch (parseError) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cache', parseError);
        }
      }

      throw Exception('Failed to load translations: $e');
    }
  }

  Future<List<BibleBook>> getBooksForTranslation(String translationId) async {
    BibleLogger.log('[BibleRepository] Fetching books for translation: $translationId');

    final cacheKey = BibleCacheService.booksCacheKey(translationId);

    // Try cache first
    final cachedData = await _cacheService.getCachedData(cacheKey);
    if (cachedData != null) {
      BibleLogger.log('[BibleRepository] Loading books from cache');
      try {
        return await compute(_parseBooks, cachedData);
      } catch (e) {
        BibleLogger.warning('[BibleRepository] Failed to parse cached books: $e');
      }
    }

    // Check connectivity
    final hasConnectivity = await _hasConnectivity();
    if (!hasConnectivity) {
      BibleLogger.warning('[BibleRepository] No connectivity, checking for stale cache...');
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        try {
          return await compute(_parseBooks, staleCache);
        } catch (e) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cached books', e);
        }
      }
      throw Exception('No internet connection and no cached data available');
    }

    // Fetch from network
    try {
      final url = '$baseUrl/$translationId/books.json';
      final response = await _makeRequest(url);

      // Cache the response
      await _cacheService.cacheData(cacheKey, response.body);

      // Parse in isolate
      final books = await compute(_parseBooks, response.body);
      BibleLogger.success('[BibleRepository] Loaded ${books.length} books from network');

      return books;
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleRepository] Network request failed', e, stackTrace);

      // Last resort: try stale cache
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        BibleLogger.warning('[BibleRepository] Serving stale cache due to network error');
        try {
          return await compute(_parseBooks, staleCache);
        } catch (parseError) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cache', parseError);
        }
      }

      throw Exception('Failed to load books: $e');
    }
  }

  Future<BibleChapter> getChapter(
    String translationId,
    String bookId,
    int chapterNumber,
  ) async {
    BibleLogger.log('[BibleRepository] Fetching chapter: $translationId/$bookId/$chapterNumber');

    final cacheKey = BibleCacheService.chapterCacheKey(translationId, bookId, chapterNumber);

    // Try cache first
    final cachedData = await _cacheService.getCachedData(cacheKey);
    if (cachedData != null) {
      BibleLogger.log('[BibleRepository] Loading chapter from cache');
      try {
        return await compute(_parseChapter, cachedData);
      } catch (e) {
        BibleLogger.warning('[BibleRepository] Failed to parse cached chapter: $e');
      }
    }

    // Check connectivity
    final hasConnectivity = await _hasConnectivity();
    if (!hasConnectivity) {
      BibleLogger.warning('[BibleRepository] No connectivity, checking for stale cache...');
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        try {
          return await compute(_parseChapter, staleCache);
        } catch (e) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cached chapter', e);
        }
      }
      throw Exception('No internet connection and no cached data available');
    }

    // Fetch from network
    try {
      final url = '$baseUrl/$translationId/$bookId/$chapterNumber.json';
      final response = await _makeRequest(url);

      // Cache the response
      await _cacheService.cacheData(cacheKey, response.body);

      // Parse in isolate
      final chapter = await compute(_parseChapter, response.body);
      BibleLogger.success('[BibleRepository] Loaded chapter from network');

      return chapter;
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleRepository] Network request failed', e, stackTrace);

      // Last resort: try stale cache
      final staleCache = await _cacheService.getCachedDataIgnoringExpiry(cacheKey);
      if (staleCache != null) {
        BibleLogger.warning('[BibleRepository] Serving stale cache due to network error');
        try {
          return await compute(_parseChapter, staleCache);
        } catch (parseError) {
          BibleLogger.error('[BibleRepository] Failed to parse stale cache', parseError);
        }
      }

      throw Exception('Failed to load chapter: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }

  // Static methods for isolate parsing
  static List<BibleTranslation> _parseTranslations(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return (data['translations'] as List<dynamic>)
        .map((e) => BibleTranslation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<BibleBook> _parseBooks(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return (data['books'] as List<dynamic>)
        .map((e) => BibleBook.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static BibleChapter _parseChapter(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return BibleChapter.fromJson(data);
  }

  List<BibleTranslation> _sortTranslations(List<BibleTranslation> translations) {
    translations.sort((a, b) {
      if (a.language == 'tel' && b.language != 'tel') return -1;
      if (a.language != 'tel' && b.language == 'tel') return 1;
      if (a.language == 'eng' && b.language != 'eng') return -1;
      if (a.language != 'eng' && b.language == 'eng') return 1;
      return a.name.compareTo(b.name);
    });
    return translations;
  }
}