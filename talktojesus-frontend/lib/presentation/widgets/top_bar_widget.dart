import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/enums/app_language.dart';
import 'language_toggle_widget.dart';
import 'subscription_badge.dart';

class TopBarWidget extends StatelessWidget {
  final Function(AppLanguage)? onLanguageChanged;
  final VoidCallback? onMenuTap;

  const TopBarWidget({
    super.key,
    this.onLanguageChanged,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMenuButton(),
          LanguageToggleWidget(onLanguageChanged: onLanguageChanged),
          const SubscriptionBadge(),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: onMenuTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: AppColors.whiteTransparent5.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: AppColors.blackTransparent10),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: SvgPicture.asset(
              'assets/svg/side-bar.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.8),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
