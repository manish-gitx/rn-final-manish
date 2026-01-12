import 'package:flutter/material.dart';
import '../../../core/constants/audio_player_constants.dart';

class AlbumArtWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const AlbumArtWidget({
    super.key,
    this.imageUrl,
    this.size = AudioPlayerConstants.albumArtSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: AudioPlayerConstants.albumArtPlaceholderColor,
        shape: RoundedRectangleBorder(
          borderRadius: AudioPlayerConstants.albumArtBorderRadius,
        ),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.grey,
            )
          : null,
    );
  }
}