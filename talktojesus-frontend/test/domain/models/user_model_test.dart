import 'package:flutter_test/flutter_test.dart';
import 'package:talktojesus/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    final sampleJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'photo_url': 'https://photo.url/img.jpg',
      'conversation_count': 5,
      'created_at': '2025-01-01T00:00:00.000Z',
      'last_login_at': '2025-06-15T12:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final user = UserModel.fromJson(sampleJson);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoUrl, 'https://photo.url/img.jpg');
      expect(user.conversationCount, 5);
      expect(user.createdAt, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(user.lastLoginAt, DateTime.parse('2025-06-15T12:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        ...sampleJson,
        'photo_url': null,
        'last_login_at': null,
        'conversation_count': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.photoUrl, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.conversationCount, 0); // defaults to 0
    });

    test('toJson produces correct snake_case keys', () {
      final user = UserModel.fromJson(sampleJson);
      final json = user.toJson();

      expect(json['id'], 'user-123');
      expect(json['display_name'], 'Test User');
      expect(json['photo_url'], 'https://photo.url/img.jpg');
      expect(json['conversation_count'], 5);
      expect(json.containsKey('created_at'), isTrue);
      expect(json.containsKey('last_login_at'), isTrue);
    });

    test('fromJson/toJson round-trip preserves data', () {
      final user = UserModel.fromJson(sampleJson);
      final roundTripped = UserModel.fromJson(user.toJson());

      expect(roundTripped.id, user.id);
      expect(roundTripped.email, user.email);
      expect(roundTripped.displayName, user.displayName);
      expect(roundTripped.conversationCount, user.conversationCount);
    });

    test('copyWith creates a new instance with updated fields', () {
      final user = UserModel.fromJson(sampleJson);
      final updated = user.copyWith(displayName: 'New Name', conversationCount: 10);

      expect(updated.displayName, 'New Name');
      expect(updated.conversationCount, 10);
      expect(updated.id, user.id); // unchanged
      expect(updated.email, user.email); // unchanged
    });

    test('isTester returns true for tester user ID', () {
      final testerJson = {
        ...sampleJson,
        'id': 'd14afd03-f04e-433e-91d9-909dc53bee23',
      };
      final user = UserModel.fromJson(testerJson);
      expect(user.isTester, isTrue);
    });

    test('isTester returns false for regular user', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.isTester, isFalse);
    });
  });

  group('CreateOrGetUserResponse', () {
    test('fromJson parses nested user and token', () {
      final json = {
        'user': {
          'id': 'user-1',
          'email': 'a@b.com',
          'display_name': 'A',
          'conversation_count': 0,
          'created_at': '2025-01-01T00:00:00.000Z',
        },
        'token': 'jwt-token-123',
      };

      final response = CreateOrGetUserResponse.fromJson(json);

      expect(response.user.id, 'user-1');
      expect(response.user.email, 'a@b.com');
      expect(response.token, 'jwt-token-123');
    });

    test('fromJson handles null token', () {
      final json = {
        'user': {
          'id': 'user-1',
          'email': 'a@b.com',
          'display_name': 'A',
          'conversation_count': 0,
          'created_at': '2025-01-01T00:00:00.000Z',
        },
        'token': null,
      };

      final response = CreateOrGetUserResponse.fromJson(json);
      expect(response.token, isNull);
    });
  });
}
