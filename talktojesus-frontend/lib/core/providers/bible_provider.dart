import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/bible_logger.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/services/bible_cache_service.dart';
import '../../domain/models/bible_translation.dart';
import '../../domain/models/bible_cache.dart';

final bibleCacheServiceProvider = Provider<BibleCacheService>((ref) {
  return BibleCacheService();
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  final cacheService = ref.watch(bibleCacheServiceProvider);
  return BibleRepository(cacheService);
});

class BibleState {
  final List<BibleTranslation>? translations;
  final BibleTranslation? selectedTranslation;
  final List<BibleBook>? books;
  final BibleBook? selectedBook;
  final BibleChapter? currentChapter;
  final int selectedChapterNumber;
  final bool isLoading;
  final String? error;
  final double scrollPosition;
  final bool isRestoringPosition;

  BibleState({
    this.translations,
    this.selectedTranslation,
    this.books,
    this.selectedBook,
    this.currentChapter,
    this.selectedChapterNumber = 1,
    this.isLoading = false,
    this.error,
    this.scrollPosition = 0.0,
    this.isRestoringPosition = false,
  });

  BibleState copyWith({
    List<BibleTranslation>? translations,
    BibleTranslation? selectedTranslation,
    List<BibleBook>? books,
    BibleBook? selectedBook,
    BibleChapter? currentChapter,
    int? selectedChapterNumber,
    bool? isLoading,
    String? error,
    double? scrollPosition,
    bool? isRestoringPosition,
  }) {
    return BibleState(
      translations: translations ?? this.translations,
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      books: books ?? this.books,
      selectedBook: selectedBook ?? this.selectedBook,
      currentChapter: currentChapter ?? this.currentChapter,
      selectedChapterNumber: selectedChapterNumber ?? this.selectedChapterNumber,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isRestoringPosition: isRestoringPosition ?? this.isRestoringPosition,
    );
  }
}

class BibleNotifier extends StateNotifier<BibleState> {
  final BibleRepository _repository;
  final BibleCacheService _cacheService;
  Timer? _scrollDebounceTimer;

  BibleNotifier(this._repository, this._cacheService) : super(BibleState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cacheService.performMaintenance();
      await loadTranslations();
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Initialization failed', e, stackTrace);
    }
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> loadTranslations() async {
    BibleLogger.log('[BibleNotifier] loadTranslations() called');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final translations = await _repository.getAvailableTranslations();
      BibleLogger.log('[BibleNotifier] Received ${translations.length} translations');

      state = state.copyWith(
        translations: translations,
        isLoading: false,
      );

      // Try to restore last selected translation
      final lastTranslationId = await _cacheService.getLastTranslationId();
      final lastPosition = await _cacheService.getLastReadingPosition();

      if (lastTranslationId != null) {
        final translationToLoad = translations.firstWhere(
          (t) => t.id == lastTranslationId,
          orElse: () => translations.first,
        );
        await selectTranslation(translationToLoad, restoreGlobally: lastPosition?.translationId == translationToLoad.id);
      } else if (lastPosition != null) {
        BibleLogger.log('[BibleNotifier] Restoring last reading position: ${lastPosition.bookId} ${lastPosition.chapterNumber}');
        await _restoreReadingPosition(lastPosition);
      } else {
        // Auto-select first translation
        if (translations.isNotEmpty) {
          BibleLogger.log('[BibleNotifier] Auto-selecting first translation: ${translations.first.name}');
          await selectTranslation(translations.first);
        } else {
          BibleLogger.warning('[BibleNotifier] No translations available to auto-select');
        }
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Error in loadTranslations', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _restoreReadingPosition(ReadingPosition position) async {
    try {
      state = state.copyWith(isRestoringPosition: true);

      // Find the translation
      final translation = state.translations?.firstWhere(
        (t) => t.id == position.translationId,
        orElse: () => state.translations!.first,
      );

      if (translation != null) {
        // Load books for this translation
        final books = await _repository.getBooksForTranslation(translation.id);

        // Find the book
        final book = books.firstWhere(
          (b) => b.id == position.bookId,
          orElse: () => books.first,
        );

        // Update state with restored position
        state = state.copyWith(
          selectedTranslation: translation,
          books: books,
          selectedBook: book,
          selectedChapterNumber: position.chapterNumber,
          scrollPosition: position.scrollPosition,
        );

        // Load the chapter
        await loadChapter(position.chapterNumber, restoreScroll: true);

        state = state.copyWith(isRestoringPosition: false);
        BibleLogger.success('[BibleNotifier] Reading position restored successfully');
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Failed to restore reading position', e, stackTrace);
      state = state.copyWith(isRestoringPosition: false);
      // Fall back to default selection
      if (state.translations != null && state.translations!.isNotEmpty) {
        await selectTranslation(state.translations!.first);
      }
    }
  }

  Future<void> selectTranslation(BibleTranslation translation, {bool restoreGlobally = false}) async {
    BibleLogger.log('[BibleNotifier] selectTranslation: ${translation.name} (${translation.id})');
    state = state.copyWith(
      selectedTranslation: translation,
      isLoading: true,
      error: null,
      currentChapter: null,
      selectedBook: null,
    );
    await _cacheService.saveLastTranslationId(translation.id);

    try {
      final books = await _repository.getBooksForTranslation(translation.id);
      BibleLogger.log('[BibleNotifier] Received ${books.length} books');

      state = state.copyWith(books: books);

      // Restore position for this specific translation
      final lastPositionForTranslation = restoreGlobally
          ? await _cacheService.getLastReadingPosition()
          : await _cacheService.getLastReadingPositionForTranslation(translation.id);

      if (lastPositionForTranslation != null && lastPositionForTranslation.translationId == translation.id) {
        BibleLogger.log('[BibleNotifier] Restoring position for ${translation.shortName}: ${lastPositionForTranslation.bookId} Ch ${lastPositionForTranslation.chapterNumber}');
        await _restoreReadingPosition(lastPositionForTranslation);
      } else {
        // Auto-select first book (Genesis) if no position is stored for this translation
        if (books.isNotEmpty) {
          BibleLogger.log('[BibleNotifier] Auto-selecting first book: ${books.first.name}');
          await selectBook(books.first);
        } else {
          BibleLogger.warning('[BibleNotifier] No books available to auto-select');
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Error in selectTranslation', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectBook(BibleBook book) async {
    BibleLogger.log('[BibleNotifier] selectBook: ${book.name} (${book.id})');
    state = state.copyWith(
      selectedBook: book,
      selectedChapterNumber: 1,
      currentChapter: null,
      isLoading: true,
    );
    await loadChapter(1);
  }

  Future<void> selectBookAndChapter(BibleBook book, int chapterNumber) async {
    BibleLogger.log('[BibleNotifier] selectBookAndChapter: ${book.name} chapter $chapterNumber');
    if (state.selectedBook?.id == book.id && state.selectedChapterNumber == chapterNumber) {
      BibleLogger.log('[BibleNotifier] Same book and chapter selected, skipping load');
      return;
    }
    state = state.copyWith(
      selectedBook: book,
      selectedChapterNumber: chapterNumber,
      currentChapter: null,
      isLoading: true,
    );
    await loadChapter(chapterNumber);
  }

  Future<void> loadChapter(int chapterNumber, {bool restoreScroll = false}) async {
    BibleLogger.log('[BibleNotifier] loadChapter: chapter $chapterNumber');

    if (state.selectedTranslation == null || state.selectedBook == null) {
      BibleLogger.warning('[BibleNotifier] Cannot load chapter: translation or book not selected');
      return;
    }

    BibleLogger.log('[BibleNotifier] Loading ${state.selectedBook!.name} chapter $chapterNumber from ${state.selectedTranslation!.shortName}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final chapter = await _repository.getChapter(
        state.selectedTranslation!.id,
        state.selectedBook!.id,
        chapterNumber,
      );

      BibleLogger.success('[BibleNotifier] Chapter loaded successfully');

      // Reset scroll position unless we're restoring
      final newScrollPosition = restoreScroll ? state.scrollPosition : 0.0;

      state = state.copyWith(
        currentChapter: chapter,
        selectedChapterNumber: chapterNumber,
        isLoading: false,
        scrollPosition: newScrollPosition,
      );

      // Save reading position
      await _saveReadingPosition();
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Error in loadChapter', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _saveReadingPosition() async {
    if (state.selectedTranslation == null || state.selectedBook == null) {
      return;
    }

    try {
      final position = ReadingPosition(
        translationId: state.selectedTranslation!.id,
        bookId: state.selectedBook!.id,
        chapterNumber: state.selectedChapterNumber,
        scrollPosition: state.scrollPosition,
        lastReadAt: DateTime.now(),
      );

      await _cacheService.saveReadingPosition(position);
      BibleLogger.log('[BibleNotifier] Reading position saved');
    } catch (e, stackTrace) {
      BibleLogger.error('[BibleNotifier] Failed to save reading position', e, stackTrace);
    }
  }

  void updateScrollPosition(double position) {
    state = state.copyWith(scrollPosition: position);

    // Debounce saving to avoid excessive writes
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveReadingPosition();
    });
  }

  Future<void> nextChapter() async {
    if (state.selectedBook == null) {
      BibleLogger.warning('[BibleNotifier] Cannot go to next chapter: no book selected');
      return;
    }

    BibleLogger.log('[BibleNotifier] nextChapter() called. Current: ${state.selectedChapterNumber}, Max: ${state.selectedBook!.numberOfChapters}');

    if (state.selectedChapterNumber < state.selectedBook!.numberOfChapters) {
      await loadChapter(state.selectedChapterNumber + 1);
    } else {
      BibleLogger.warning('[BibleNotifier] Already at last chapter');
    }
  }

  Future<void> previousChapter() async {
    BibleLogger.log('[BibleNotifier] previousChapter() called. Current: ${state.selectedChapterNumber}');

    if (state.selectedChapterNumber > 1) {
      await loadChapter(state.selectedChapterNumber - 1);
    } else {
      BibleLogger.warning('[BibleNotifier] Already at first chapter');
    }
  }
}

final bibleProvider = StateNotifierProvider<BibleNotifier, BibleState>((ref) {
  final repository = ref.watch(bibleRepositoryProvider);
  final cacheService = ref.watch(bibleCacheServiceProvider);
  return BibleNotifier(repository, cacheService);
});