import 'package:flutter/material.dart';

class AudioPlayerConstants {
  static const double albumArtSize = 288.0;
  static const double playButtonSize = 64.0;
  static const double controlButtonSize = 32.0;
  static const double trackHeight = 4.0;
  static const double thumbRadius = 8.0;
  static const double horizontalPadding = 16.0;
  static const double controlsPadding = 60.0;

  static const EdgeInsets pageHorizontalPadding = EdgeInsets.only(left: 16, right: 16);
  static const EdgeInsets controlsHorizontalPadding = EdgeInsets.symmetric(horizontal: 60);

  static const Color activeTrackColor = Color(0xCC2057FC);
  static const Color thumbColor = Color(0xFFD9D9D9);
  static const Color albumArtPlaceholderColor = Color(0xFFD9D9D9);
  static const Color backgroundOverlayColor = Colors.black;
  static const double backgroundOverlayOpacity = 0.70;
  static const double textOpacity = 0.50;

  static const BorderRadius albumArtBorderRadius = BorderRadius.all(Radius.circular(8));

  static const String backgroundImagePath = 'assets/images/jesus_backdrop.png';
  static const String playIconPath = 'assets/svg/play.svg';
  static const String pauseIconPath = 'assets/svg/pause.svg';
  static const String nextSongIconPath = 'assets/svg/next_song.svg';

  static const Duration mockTotalDuration = Duration(minutes: 3, seconds: 30);
}