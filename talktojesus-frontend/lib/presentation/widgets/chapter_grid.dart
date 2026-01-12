import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';

class ChapterGrid extends StatelessWidget {
  final int totalChapters;
  final Function(int) onChapterSelected;

  const ChapterGrid({
    super.key,
    required this.totalChapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildRows(),
    );
  }

  List<Widget> _buildRows() {
    List<Widget> rows = [];
    const int chaptersPerRow = 6;

    for (int i = 0; i < totalChapters; i += chaptersPerRow) {
      rows.add(_buildRow(i, chaptersPerRow));
      if (i + chaptersPerRow < totalChapters) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return rows;
  }

  Widget _buildRow(int startIndex, int chaptersPerRow) {
    List<Widget> rowChildren = [];

    for (int j = startIndex;
        j < startIndex + chaptersPerRow && j < totalChapters;
        j++) {
      rowChildren.add(_ChapterBox(
        chapterNumber: j + 1,
        onTap: () => onChapterSelected(j + 1),
      ));

      if (j < startIndex + chaptersPerRow - 1 && j < totalChapters - 1) {
        rowChildren.add(const SizedBox(width: 8));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: rowChildren,
    );
  }
}

class _ChapterBox extends StatelessWidget {
  final int chapterNumber;
  final VoidCallback onTap;

  const _ChapterBox({
    required this.chapterNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        child: Center(
          child: Text(
            '$chapterNumber',
            textAlign: TextAlign.center,
            style: AppTextStyles.chapterNumberText,
          ),
        ),
      ),
    );
  }
}