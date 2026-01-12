class ConversationResponse {
  final bool success;
  final String userMessage;
  final String assistantText;
  final String assistantAudio; // Base64 encoded audio

  ConversationResponse({
    required this.success,
    required this.userMessage,
    required this.assistantText,
    required this.assistantAudio,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    return ConversationResponse(
      success: json['success'] as bool? ?? false,
      userMessage: json['user_message'] as String? ?? '',
      assistantText: json['assistant_text'] as String? ?? '',
      assistantAudio: json['assistant_audio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user_message': userMessage,
      'assistant_text': assistantText,
      'assistant_audio': assistantAudio,
    };
  }
}
