import 'package:flutter/material.dart';

class AppColors {
  // Standard colors
  static const Color jesusSongsBackground = Color(0x662057FC);
  static const Color bibleBackground = Color(0x66FC1DA7);
  static const Color purpleButton = Color(0xFF6E43A6);
  static const Color whiteTransparent5 = Color(0x0DFFFFFF);
  static const Color whiteTransparent20 = Color(0x33FFFFFF);
  static const Color blackTransparent10 = Color(0x1A000000);
  static const Color blackTransparent20 = Color(0x33000000);

  // High contrast colors
  static const Color highContrastBackground = Color(0xFF000000);
  static const Color highContrastSurface = Color(0xFF1A1A1A);
  static const Color highContrastPrimary = Color(0xFFFFFFFF);
  static const Color highContrastSecondary = Color(0xFFFFFF00);
  static const Color highContrastError = Color(0xFFFF0000);
  static const Color highContrastSuccess = Color(0xFF00FF00);
  static const Color highContrastWarning = Color(0xFFFFAA00);

  static ColorScheme getColorScheme({
    required bool isHighContrast,
    required Brightness brightness,
  }) {
    if (isHighContrast) {
      return brightness == Brightness.dark
          ? _getHighContrastDarkColorScheme()
          : _getHighContrastLightColorScheme();
    }

    return ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );
  }

  static ColorScheme _getHighContrastDarkColorScheme() {
    return const ColorScheme.dark(
      primary: highContrastPrimary,
      onPrimary: highContrastBackground,
      secondary: highContrastSecondary,
      onSecondary: highContrastBackground,
      surface: highContrastSurface,
      onSurface: highContrastPrimary,
      error: highContrastError,
      onError: highContrastPrimary,
      outline: highContrastPrimary,
      outlineVariant: highContrastSecondary,
    );
  }

  static ColorScheme _getHighContrastLightColorScheme() {
    return const ColorScheme.light(
      primary: highContrastBackground,
      onPrimary: highContrastPrimary,
      secondary: highContrastBackground,
      onSecondary: highContrastSecondary,
      surface: highContrastPrimary,
      onSurface: highContrastBackground,
      error: highContrastError,
      onError: highContrastPrimary,
      outline: highContrastBackground,
      outlineVariant: highContrastBackground,
    );
  }

  static Color getAdaptiveColor({
    required Color standardColor,
    required Color highContrastColor,
    required bool isHighContrast,
  }) {
    return isHighContrast ? highContrastColor : standardColor;
  }
}