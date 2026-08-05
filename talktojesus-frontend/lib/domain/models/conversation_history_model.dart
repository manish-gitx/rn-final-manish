/// One past conversation turn, as returned by `GET /api/conversation/history`.
class ConversationHistoryEntry {
  final String id;
  final String language;
  final String inputMode;
  final String? userMessage;
  final String? assistantText;
  final int? totalMs;
  final DateTime? createdAt;

  const ConversationHistoryEntry({
    required this.id,
    required this.language,
    required this.inputMode,
    this.userMessage,
    this.assistantText,
    this.totalMs,
    this.createdAt,
  });

  factory ConversationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ConversationHistoryEntry(
      id: json['id']?.toString() ?? '',
      language: json['language'] as String? ?? 'en',
      inputMode: json['input_mode'] as String? ?? 'voice',
      userMessage: json['user_message'] as String?,
      assistantText: json['assistant_text'] as String?,
      totalMs: json['total_ms'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'input_mode': inputMode,
      'user_message': userMessage,
      'assistant_text': assistantText,
      'total_ms': totalMs,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationHistoryEntry &&
        other.id == id &&
        other.language == language &&
        other.inputMode == inputMode &&
        other.userMessage == userMessage &&
        other.assistantText == assistantText &&
        other.totalMs == totalMs &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        language,
        inputMode,
        userMessage,
        assistantText,
        totalMs,
        createdAt,
      );
}
