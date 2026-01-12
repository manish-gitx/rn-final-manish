import 'package:flutter/material.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/audio_player_constants.dart';
import '../../../domain/models/song.dart';

class SongInfoWidget extends StatelessWidget {
  final Song song;

  const SongInfoWidget({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title,
            style: AppTextStyles.songTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Opacity(
            opacity: AudioPlayerConstants.textOpacity,
            child: Text(
              song.duration,
              style: AppTextStyles.songDurationStyle,
            ),
          ),
        ],
      ),
    );
  }
}