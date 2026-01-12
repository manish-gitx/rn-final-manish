import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../core/navigation/navigation_service.dart';

class BibleHeader extends StatelessWidget {
  final String selectedBook;
  final int selectedChapter;
  final String selectedVersion;
  final VoidCallback onBookChapterTap;
  final VoidCallback onVersionTap;

  const BibleHeader({
    super.key,
    required this.selectedBook,
    required this.selectedChapter,
    required this.selectedVersion,
    required this.onBookChapterTap,
    required this.onVersionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BackButton(),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _BookChapterSelector(
                    selectedBook: selectedBook,
                    selectedChapter: selectedChapter,
                    onTap: onBookChapterTap,
                  ),
                  _VersionSelector(
                    selectedVersion: selectedVersion,
                    onTap: onVersionTap,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: GestureDetector(
        onTap: () => NavigationService.pop(),
        behavior: HitTestBehavior.opaque,
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _BookChapterSelector extends StatelessWidget {
  final String selectedBook;
  final int selectedChapter;
  final VoidCallback onTap;

  const _BookChapterSelector({
    required this.selectedBook,
    required this.selectedChapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 6, left: 12, right: 6, bottom: 6),
        decoration: const ShapeDecoration(
          color: Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(99),
              bottomLeft: Radius.circular(99),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$selectedBook $selectedChapter',
              style: AppTextStyles.bibleChapterSelector,
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionSelector extends StatelessWidget {
  final String selectedVersion;
  final VoidCallback onTap;

  const _VersionSelector({
    required this.selectedVersion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 6, left: 6, right: 12, bottom: 6),
        decoration: ShapeDecoration(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.white.withValues(alpha: 0.10),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(99),
              bottomRight: Radius.circular(99),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              selectedVersion,
              style: AppTextStyles.bibleChapterSelector,
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}