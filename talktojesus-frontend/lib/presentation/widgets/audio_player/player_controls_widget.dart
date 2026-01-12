import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/audio_player_constants.dart';
import '../../../core/accessibility/accessibility_utils.dart';

class PlayerControlsWidget extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PlayerControlsWidget({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AudioPlayerConstants.controlsHorizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            iconPath: AudioPlayerConstants.nextSongIconPath,
            size: AudioPlayerConstants.controlButtonSize,
            onTap: onPrevious,
            transform: Matrix4.rotationY(3.14159),
          ),
          _ControlButton(
            iconPath: isPlaying ? AudioPlayerConstants.pauseIconPath : AudioPlayerConstants.playIconPath,
            size: AudioPlayerConstants.playButtonSize,
            onTap: onPlayPause,
          ),
          _ControlButton(
            iconPath: AudioPlayerConstants.nextSongIconPath,
            size: AudioPlayerConstants.controlButtonSize,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String iconPath;
  final double size;
  final VoidCallback? onTap;
  final Matrix4? transform;

  const _ControlButton({
    required this.iconPath,
    required this.size,
    this.onTap,
    this.transform,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = SvgPicture.asset(
      iconPath,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        Colors.white,
        BlendMode.srcIn,
      ),
    );

    if (transform != null) {
      icon = Transform(
        transform: transform!,
        alignment: Alignment.center,
        child: icon,
      );
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          AccessibilityUtils.provideFeedback();
          onTap!();
        }
      },
      child: icon,
    );
  }
}