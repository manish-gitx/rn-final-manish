import 'package:flutter/widgets.dart';

/// Resolves a [Song.imageUrl] to an [ImageProvider].
///
/// Bundled artwork is stored as an asset path (`assets/images/hymns/...`),
/// while songs served by the backend supply an absolute URL — this lets both
/// render through the same widgets.
ImageProvider songImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return AssetImage(path);
}

bool isRemoteArtwork(String path) =>
    path.startsWith('http://') || path.startsWith('https://');
