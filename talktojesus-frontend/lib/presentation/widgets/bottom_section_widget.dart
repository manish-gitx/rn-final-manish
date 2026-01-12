import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'navigation_button.dart';
import 'inspirational_message_widget.dart';

class BottomSectionWidget extends StatelessWidget {
  final VoidCallback onJesusSongsTap;
  final VoidCallback onBibleTap;
  final Function(String)? onInputSubmitted;
  final TextEditingController? inputController;
  final bool isVoiceEnabled;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCancelRecording;
  final bool isRecording;
  final bool isProcessing;

  const BottomSectionWidget({
    super.key,
    required this.onJesusSongsTap,
    required this.onBibleTap,
    this.onInputSubmitted,
    this.inputController,
    this.isVoiceEnabled = false,
    this.onVoiceTap,
    this.onCancelRecording,
    this.isRecording = false,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 0, // Changed to 0 to allow overflow
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const InspirationalMessageWidget(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                child: _buildNavigationButtons(),
              ),
            ),
            const SizedBox(height: 8),
            // TODO: Input box temporarily commented out - will be replaced with voice input
            // InputFieldWidget(
            //   controller: inputController,
            //   onSubmitted: onInputSubmitted,
            // ),
            // Voice input bar - spans the full width
            _buildVoiceInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // TODO: Jesus Songs button temporarily commented out
        // NavigationButton(
        //   label: 'Jesus Songs',
        //   iconPath: 'assets/svg/music.svg',
        //   backgroundColor: AppColors.jesusSongsBackground,
        //   onTap: onJesusSongsTap,
        //   heroTag: 'jesus_songs_button',
        // ),
        // const SizedBox(width: 8),
        NavigationButton(
          label: 'Bible',
          iconPath: 'assets/svg/bible.svg',
          backgroundColor: AppColors.bibleBackground,
          onTap: onBibleTap,
          heroTag: 'bible_button',
        ),
      ],
    );
  }

  Widget _buildVoiceInputBar() {
    if (isProcessing) {
      return _buildProcessingBar();
    }

    if (isRecording) {
      return _buildRecordingBar();
    }

    return _buildIdleBar();
  }

  Widget _buildIdleBar() {
    return InkWell(
      onTap: isVoiceEnabled && onVoiceTap != null ? onVoiceTap : null,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isVoiceEnabled ? 0.80 : 0.40,
                  child: Container(
                    width: 26,
                    height: 26,
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
                const SizedBox(width: 12),
                Flexible(
                  child: Opacity(
                    opacity: isVoiceEnabled ? 0.80 : 0.40,
                    child: Text(
                      'యేసుతో మాట్లాడండి',
                      style: AppTextStyles.placeholderText.copyWith(
                        color: Colors.white.withValues(
                          alpha: isVoiceEnabled ? 0.8 : 0.4,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cancel button
              GestureDetector(
                onTap: onCancelRecording,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              // Recording indicator
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Opacity(
                      opacity: 0.80,
                      child: Text(
                        'Recording...',
                        style: AppTextStyles.placeholderText.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Stop button
              GestureDetector(
                onTap: onVoiceTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.stop_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Opacity(
                  opacity: 0.80,
                  child: Text(
                    'నీ హృదయాన్ని వినిపిస్తున్నావు',
                    style: AppTextStyles.placeholderText.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
