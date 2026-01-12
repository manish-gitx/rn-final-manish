import 'package:flutter/material.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/audio_player_constants.dart';
import '../../../core/accessibility/accessibility_utils.dart';

class ProgressBarWidget extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeek;
  final String Function(Duration) formatDuration;

  const ProgressBarWidget({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: AudioPlayerConstants.trackHeight,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: AudioPlayerConstants.thumbRadius,
              ),
              activeTrackColor: AudioPlayerConstants.activeTrackColor,
              inactiveTrackColor: Colors.white.withValues(alpha: AudioPlayerConstants.textOpacity),
              thumbColor: AudioPlayerConstants.thumbColor,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: currentPosition.inSeconds.toDouble(),
              max: totalDuration.inSeconds.toDouble(),
              onChanged: (value) {
                AccessibilityUtils.provideFeedback();
                onSeek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Opacity(
                opacity: AudioPlayerConstants.textOpacity,
                child: Text(
                  formatDuration(currentPosition),
                  style: AppTextStyles.songDurationStyle,
                ),
              ),
              Opacity(
                opacity: AudioPlayerConstants.textOpacity,
                child: Text(
                  formatDuration(totalDuration),
                  style: AppTextStyles.songDurationStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}