import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/accessibility/accessibility_utils.dart';

class NavigationButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String? heroTag;

  const NavigationButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.backgroundColor,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget innerContent = InkWell(
      onTap: () {
        AccessibilityUtils.provideFeedback();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              color: backgroundColor.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: AppColors.blackTransparent10,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.80,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.buttonText,
                  ),
                ),
                const SizedBox(width: 4.89),
                Opacity(
                  opacity: 0.80,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Expanded(
        child: Hero(
          tag: heroTag!,
          child: Material(
            color: Colors.transparent,
            child: innerContent,
          ),
        ),
      );
    }

    return Expanded(child: innerContent);
  }
}