import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/text_styles.dart';
import '../../core/providers/bible_provider.dart';
import '../../core/utils/bible_logger.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../domain/models/bible_translation.dart';
import 'chapter_grid.dart';

class BookSelectorBottomSheet extends ConsumerStatefulWidget {
  const BookSelectorBottomSheet({super.key});

  @override
  ConsumerState<BookSelectorBottomSheet> createState() =>
      _BookSelectorBottomSheetState();

  static void show(BuildContext context) {
    BibleLogger.log('[BookSelectorBottomSheet] Showing bottom sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookSelectorBottomSheet(),
    );
  }
}

class _BookSelectorBottomSheetState extends ConsumerState<BookSelectorBottomSheet> {
  String? expandedBookId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BibleBook> _filterBooks(List<BibleBook> books) {
    if (_searchQuery.isEmpty) return books;

    final query = _searchQuery.toLowerCase();
    return books.where((b) =>
      b.name.toLowerCase().contains(query) ||
      b.commonName.toLowerCase().contains(query) ||
      b.id.toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    final books = bibleState.books ?? [];
    final filteredBooks = _filterBooks(books);

    BibleLogger.log('[BookSelectorBottomSheet] Building. Books: ${books.length}');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF383433),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Book & Chapter',
            textAlign: TextAlign.center,
            style: AppTextStyles.bottomSheetTitle,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: AppTextStyles.bibleChapterSelector.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search books...',
              hintStyle: AppTextStyles.versionPublisher,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF4A4443),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (bibleState.isLoading)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) => ShimmerBox(
                  width: double.infinity,
                  height: 40,
                  borderRadius: 8,
                  baseColor: const Color(0xFF4A4443),
                  highlightColor: const Color(0xFF5A5453),
                ),
              ),
            )
          else if (books.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No books available',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (filteredBooks.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No books found',
                  style: AppTextStyles.versionPublisher,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredBooks
                      .map((book) => _BookItem(
                            book: book,
                            isExpanded: expandedBookId == book.id,
                            isSelected: bibleState.selectedBook?.id == book.id,
                            onToggle: () => _toggleBook(book.id),
                            onChapterSelected: (chapter) =>
                                _handleChapterSelection(book, chapter),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleBook(String bookId) {
    BibleLogger.log('[BookSelectorBottomSheet] Toggling book: $bookId');
    setState(() {
      expandedBookId = expandedBookId == bookId ? null : bookId;
    });
  }

  void _handleChapterSelection(BibleBook book, int chapter) {
    BibleLogger.log('[BookSelectorBottomSheet] Chapter selected: ${book.name} chapter $chapter');
    ref.read(bibleProvider.notifier).selectBookAndChapter(book, chapter);
    Navigator.pop(context);
  }
}

class _BookItem extends StatelessWidget {
  final BibleBook book;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onToggle;
  final Function(int) onChapterSelected;

  const _BookItem({
    required this.book,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggle,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A4443) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: AppTextStyles.bottomSheetItemText,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${book.numberOfChapters} chapters',
                        style: AppTextStyles.versionPublisher,
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: isExpanded ? 3.14 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 10),
          ChapterGrid(
            totalChapters: book.numberOfChapters,
            onChapterSelected: onChapterSelected,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}