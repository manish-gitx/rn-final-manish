class Song {
  final String id;
  final String title;
  final String duration;
  final String? imageUrl;
  final String? audioUrl;

  const Song({
    required this.id,
    required this.title,
    required this.duration,
    this.imageUrl,
    this.audioUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'image_url': imageUrl,
      'audio_url': audioUrl,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? duration,
    String? imageUrl,
    String? audioUrl,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song &&
        other.id == id &&
        other.title == title &&
        other.duration == duration &&
        other.imageUrl == imageUrl &&
        other.audioUrl == audioUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        duration.hashCode ^
        imageUrl.hashCode ^
        audioUrl.hashCode;
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, duration: $duration, imageUrl: $imageUrl, audioUrl: $audioUrl)';
  }
}