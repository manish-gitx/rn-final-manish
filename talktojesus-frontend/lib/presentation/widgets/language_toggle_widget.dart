import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/enums/app_language.dart';
import '../../core/accessibility/accessibility_utils.dart';

class LanguageToggleWidget extends StatefulWidget {
  final Function(AppLanguage)? onLanguageChanged;

  const LanguageToggleWidget({
    super.key,
    this.onLanguageChanged,
  });

  @override
  State<LanguageToggleWidget> createState() => _LanguageToggleWidgetState();
}

class _LanguageToggleWidgetState extends State<LanguageToggleWidget> {
  AppLanguage _currentLanguage = AppLanguage.english;

  void _toggleLanguage() {
    AccessibilityUtils.provideFeedback();
    setState(() {
      _currentLanguage = _currentLanguage == AppLanguage.english
          ? AppLanguage.telugu
          : AppLanguage.english;
    });
    widget.onLanguageChanged?.call(_currentLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLanguage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: ShapeDecoration(
              color: AppColors.whiteTransparent5.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: AppColors.blackTransparent10,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(AppLanguage.english),
                const SizedBox(width: 8),
                _buildDivider(),
                const SizedBox(width: 8),
                _buildLanguageOption(AppLanguage.telugu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(AppLanguage language) {
    final isSelected = _currentLanguage == language;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: GoogleFonts.lora(
        color: isSelected
            ? Colors.white.withValues(alpha: 1.0)
            : Colors.white.withValues(alpha: 0.5),
        fontSize: isSelected ? 18 : 16,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        height: 1.20,
        letterSpacing: -0.32,
      ),
      child: Text(language.code),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}