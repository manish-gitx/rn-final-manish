import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/text_styles.dart';
import '../../core/accessibility/accessibility_utils.dart';

class InputFieldWidget extends StatelessWidget {
  final String hintText;
  final Function(String)? onSubmitted;
  final TextEditingController? controller;

  const InputFieldWidget({
    super.key,
    this.hintText = 'Ask everything and beyond...',
    this.onSubmitted,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Get safe area padding for bottom (system navigation bar on Android, home indicator on iOS)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Add bottom padding for safe area
      padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(right: 72),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(60),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        child: Stack(
        clipBehavior: Clip.none, // Allow mic button to overflow
        children: [
          // Input field container with glassy effect
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.80,
                        child: TextField(
                          controller: controller,
                          onSubmitted: onSubmitted,
                          style: AppTextStyles.placeholderText,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: hintText,
                            hintStyle: AppTextStyles.placeholderText.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mic button positioned outside on the right with glassy effect
          Positioned(
            right: -72, // Position 16px outside the container
            top: 0,
            child: InkWell(
              onTap: () {
                AccessibilityUtils.provideFeedback();
                if (onSubmitted != null && controller != null) {
                  onSubmitted!(controller!.text);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 62,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: 0.80,
                          child: Container(
                            width: 30,
                            height: 30,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(),
                            child: SvgPicture.asset(
                              'assets/svg/mic.svg',
                              colorFilter: ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}