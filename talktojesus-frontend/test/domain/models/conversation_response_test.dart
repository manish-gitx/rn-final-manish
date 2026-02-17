import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/conversation_response_model.dart';

void main() {
  group('ConversationResponse', () {
    test('fromJson parses all fields', () {
      final json = {
        'success': true,
        'user_message': 'Hello Jesus',
        'assistant_text': 'Peace be with you',
        'assistant_audio': 'base64AudioData==',
      };

      final response = ConversationResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.userMessage, 'Hello Jesus');
      expect(response.assistantText, 'Peace be with you');
      expect(response.assistantAudio, 'base64AudioData==');
    });

    test('fromJson handles null/missing fields with defaults', () {
      final json = <String, dynamic>{};

      final response = ConversationResponse.fromJson(json);

      expect(response.success, isFalse);
      expect(response.userMessage, '');
      expect(response.assistantText, '');
      expect(response.assistantAudio, '');
    });

    test('toJson produces snake_case keys', () {
      final response = ConversationResponse(
        success: true,
        userMessage: 'Hi',
        assistantText: 'Hello',
        assistantAudio: 'data',
      );

      final json = response.toJson();

      expect(json['success'], isTrue);
      expect(json['user_message'], 'Hi');
      expect(json['assistant_text'], 'Hello');
      expect(json['assistant_audio'], 'data');
    });

    test('fromJson/toJson round-trip', () {
      final original = ConversationResponse(
        success: true,
        userMessage: 'Test message',
        assistantText: 'Test response',
        assistantAudio: 'audioData',
      );

      final roundTripped = ConversationResponse.fromJson(original.toJson());

      expect(roundTripped.success, original.success);
      expect(roundTripped.userMessage, original.userMessage);
      expect(roundTripped.assistantText, original.assistantText);
      expect(roundTripped.assistantAudio, original.assistantAudio);
    });
  });
}
