import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

/// Shimmer loading widget that mimics the SongListItem layout
/// Follows Single Responsibility Principle - only handles shimmer loading state
class SongListItemShimmer extends StatelessWidget {
  const SongListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer.dark(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Album art shimmer
            const ShimmerBox(
              width: 82,
              height: 82,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 12),
            // Song details shimmer
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song title shimmer - two lines to match maxLines: 2
                  const ShimmerLine(
                    width: double.infinity,
                    height: 20,
                  ),
                  const SizedBox(height: 4),
                  const ShimmerLine(
                    width: 180,
                    height: 20,
                  ),
                  const SizedBox(height: 5),
                  // Duration shimmer - matches the 185 width from SizedBox
                  const ShimmerLine(
                    width: 185,
                    height: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading widget for multiple song list items
/// Follows DRY principle by reusing SongListItemShimmer
class SongListShimmer extends StatelessWidget {
  final int itemCount;

  const SongListShimmer({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const SongListItemShimmer(),
      ),
    );
  }
}