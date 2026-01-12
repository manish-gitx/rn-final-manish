import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/text_styles.dart';
import '../../core/providers/bible_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/utils/bible_logger.dart';
import '../../domain/models/bible_translation.dart';
import '../widgets/bible_header.dart';
import '../widgets/bible_version_bottom_sheet.dart';
import '../widgets/book_selector_bottom_sheet.dart';

class BiblePage extends ConsumerStatefulWidget {
  const BiblePage({super.key});

  @override
  ConsumerState<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends ConsumerState<BiblePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollRestored = false;

  @override
  void initState() {
    super.initState();
    BibleLogger.log('[BiblePage] initState() called');

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScreenView('Bible Page');
    });

    // Load translations when page is first opened
    Future.microtask(() {
      if (mounted) {
        BibleLogger.log('[BiblePage] Triggering loadTranslations()');
        ref.read(bibleProvider.notifier).loadTranslations();
      }
    });

    // Listen to scroll changes to save position
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Save scroll position periodically (debounced in provider)
    if (_scrollController.hasClients && mounted) {
      ref.read(bibleProvider.notifier).updateScrollPosition(
        _scrollController.position.pixels,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/jesus_backdrop.png'),
            fit: BoxFit.cover,
          ),
          color: Colors.black.withValues(alpha: 0.70),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final bibleState = ref.watch(bibleProvider);

    BibleLogger.log('[BiblePage] Building content - isLoading: ${bibleState.isLoading}, '
        'translations: ${bibleState.translations?.length ?? 0}, '
        'selectedTranslation: ${bibleState.selectedTranslation?.name ?? "null"}, '
        'books: ${bibleState.books?.length ?? 0}, '
        'selectedBook: ${bibleState.selectedBook?.name ?? "null"}, '
        'currentChapter: ${bibleState.currentChapter != null ? "loaded" : "null"}');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          children: [
            BibleHeader(
              selectedBook: bibleState.selectedBook?.name ?? 'Loading...',
              selectedChapter: bibleState.selectedChapterNumber,
              selectedVersion: bibleState.selectedTranslation?.shortName ?? 'Loading...',
              onBookChapterTap: _showBookSelector,
              onVersionTap: _showVersionSelector,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildBibleContentArea(bibleState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibleContentArea(BibleState bibleState) {
    if (bibleState.isLoading) {
      return _buildShimmerLoading();
    }

    if (bibleState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${bibleState.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(bibleProvider.notifier).loadTranslations();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (bibleState.currentChapter == null) {
      return const Center(
        child: Text(
          'Select a translation and book to begin reading',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Restore scroll position if needed (only once)
    if (bibleState.isRestoringPosition && bibleState.scrollPosition > 0 && !_isScrollRestored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(bibleState.scrollPosition);
          _isScrollRestored = true;
          BibleLogger.log('[BiblePage] Scroll position restored to ${bibleState.scrollPosition}');
        }
      });
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(bibleState),
          const SizedBox(height: 24),
          _buildBibleContent(bibleState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          Container(
            width: 200,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          // Verse shimmers
          ...List.generate(8, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTitle(BibleState bibleState) {
    final chapter = bibleState.currentChapter;
    if (chapter == null) return const SizedBox();

    return Text(
      '${bibleState.selectedBook?.name ?? ''} ${bibleState.selectedChapterNumber}',
      style: AppTextStyles.bibleTitle,
    );
  }

  Widget _buildBibleContent(BibleState bibleState) {
    final chapter = bibleState.currentChapter;
    if (chapter == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: chapter.chapter.content.map((content) {
        if (content is ChapterHeading) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              content.content.join(' '),
              style: AppTextStyles.bibleTitle.copyWith(fontSize: 18),
            ),
          );
        } else if (content is ChapterLineBreak) {
          return const SizedBox(height: 8);
        } else if (content is ChapterVerse) {
          return _buildVerse(content);
        } else if (content is ChapterHebrewSubtitle) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _extractTextFromContent(content.content),
              style: AppTextStyles.bibleContent.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          );
        }
        return const SizedBox();
      }).toList(),
    );
  }

  Widget _buildVerse(ChapterVerse verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${verse.number} ',
              style: AppTextStyles.bibleContent.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: _extractTextFromContent(verse.content),
              style: AppTextStyles.bibleContent,
            ),
          ],
        ),
      ),
    );
  }

  String _extractTextFromContent(List<dynamic> content) {
    final buffer = StringBuffer();
    for (var item in content) {
      if (item is String) {
        buffer.write(item);
      } else if (item is Map) {
        if (item.containsKey('text')) {
          buffer.write(item['text']);
        } else if (item.containsKey('heading')) {
          buffer.write(item['heading']);
        } else if (item.containsKey('lineBreak')) {
          buffer.write('\n');
        }
      }
    }
    return buffer.toString();
  }

  void _showVersionSelector() {
    if (!mounted) return;
    BibleLogger.log('[BiblePage] Showing version selector bottom sheet');
    ref.read(analyticsServiceProvider).trackFeatureUsage('Bible Version Selector');
    BibleVersionBottomSheet.show(context);
  }

  void _showBookSelector() {
    if (!mounted) return;
    final bibleState = ref.read(bibleProvider);
    BibleLogger.log('[BiblePage] Showing book selector bottom sheet');

    // Track book/chapter selector usage
    if (bibleState.selectedBook != null) {
      ref.read(analyticsServiceProvider).trackBibleBookSelected(bibleState.selectedBook!.name);
      if (bibleState.selectedChapterNumber > 0) {
        ref.read(analyticsServiceProvider).trackBibleChapterSelected(
          bibleState.selectedBook!.name,
          bibleState.selectedChapterNumber,
        );
      }
    }
    ref.read(analyticsServiceProvider).trackFeatureUsage('Bible Book Selector');

    BookSelectorBottomSheet.show(context);
  }
}