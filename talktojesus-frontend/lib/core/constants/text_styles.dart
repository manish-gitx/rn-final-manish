import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final TextStyle buttonText = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.40,
  );

  static final TextStyle placeholderText = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.40,
  );

  static final TextStyle counterText = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: -0.48,
  );

  static final TextStyle appBarTitle = GoogleFonts.poppins(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle pageTitle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static final TextStyle pageSubtitle = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.black54,
  );

  static final TextStyle pageHeader = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 23.73,
    fontWeight: FontWeight.w600,
    height: 1.20,
    letterSpacing: -0.47,
  );

  static final TextStyle songTitle = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.20,
    letterSpacing: -0.40,
  );

  static final TextStyle songDurationStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'DM Sans',
    fontWeight: FontWeight.w400,
    height: 1.20,
    letterSpacing: -0.32,
  );

  // Bible page styles
  static final TextStyle bibleChapterSelector = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.60,
    letterSpacing: -0.28,
  );

  static final TextStyle bibleTitle = GoogleFonts.playfairDisplay(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    height: 1.20,
    letterSpacing: -0.56,
  );

  static final TextStyle bibleContent = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.60,
    letterSpacing: -0.34,
  );

  // Bottom sheet styles
  static final TextStyle bottomSheetTitle = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.60,
    letterSpacing: -0.48,
  );

  static final TextStyle bottomSheetItemText = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.60,
    letterSpacing: -0.34,
  );

  static final TextStyle versionPublisher = TextStyle(
    color: Colors.white.withValues(alpha: 0.5),
    fontSize: 16,
    fontFamily: 'DM Sans',
    fontWeight: FontWeight.w400,
    height: 1.20,
    letterSpacing: -0.32,
  );

  static final TextStyle versionName = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.20,
    letterSpacing: -0.40,
  );

  static final TextStyle chapterNumberText = GoogleFonts.lora(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.60,
    letterSpacing: -0.34,
  );
}