import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../core/accessibility/accessibility_utils.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final String? heroTag;

  const PageHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Stack(
        children: [
          _buildBackground(),
          _buildTitle(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.89,
        children: [
          BackButton(onPressed: onBackPressed),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    Widget titleText = Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.pageHeader,
    );

    if (heroTag != null) {
      titleText = Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: titleText,
        ),
      );
    }

    return Positioned(
      left: 116,
      top: 10,
      child: titleText,
    );
  }
}

class BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BackButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AccessibilityUtils.provideFeedback();
        onPressed();
      },
      child: Container(
        width: 24,
        height: 24,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}