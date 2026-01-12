import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/constants/tester_constants.dart';
import 'dart:io';
import '../../domain/models/user_model.dart';
import '../../domain/models/plan_model.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/models/conversation_response_model.dart';
import 'token_service.dart';

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final TokenService _tokenService = TokenService();
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    bool isMultipart = false,
  }) async {
    final headers = <String, String>{
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      // Check if this is a tester account and use the hardcoded token
      final isTester = await _tokenService.isTesterAccount();
      final tokenToUse = isTester ? TesterConstants.testerJwtToken : _token;

      if (tokenToUse != null) {
        headers['Authorization'] = 'Bearer $tokenToUse';
      }
    }

    return headers;
  }

  Future<ApiResponse<CreateOrGetUserResponse>> createOrGetUser(
    String googleToken,
  ) async {
    try {
      debugPrint('[ApiClient] Creating or getting user with Google token...');

      final url = Uri.parse(ApiConstants.getUrl(ApiConstants.createOrGetUser));
      final body = jsonEncode({'token': googleToken});

      final headers = await _getHeaders(includeAuth: false);
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userResponse = CreateOrGetUserResponse.fromJson(data);

        // Store token for future requests
        if (userResponse.token != null) {
          setToken(userResponse.token!);
        }

        return ApiResponse<CreateOrGetUserResponse>(
          isSuccess: true,
          data: userResponse,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to create or get user';

        return ApiResponse<CreateOrGetUserResponse>(
          isSuccess: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in createOrGetUser: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<CreateOrGetUserResponse>(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      debugPrint('[ApiClient] Getting current user...');

      final url = Uri.parse(ApiConstants.getUrl(ApiConstants.getCurrentUser));

      final headers = await _getHeaders(includeAuth: true);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userModel = UserModel.fromJson(data);

        return ApiResponse<UserModel>(
          isSuccess: true,
          data: userModel,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to get current user';

        return ApiResponse<UserModel>(
          isSuccess: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in getCurrentUser: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<UserModel>(isSuccess: false, error: e.toString());
    }
  }

  Future<ApiResponse<List<Plan>>> getPlans() async {
    try {
      debugPrint('[ApiClient] Getting subscription plans...');

      final url = Uri.parse(ApiConstants.getUrl(ApiConstants.getPlans));

      final headers = await _getHeaders(includeAuth: false);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final plans = data
            .map((item) => Plan.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Plan>>(
          isSuccess: true,
          data: plans,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to get plans';

        return ApiResponse<List<Plan>>(
          isSuccess: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in getPlans: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<List<Plan>>(isSuccess: false, error: e.toString());
    }
  }

  Future<ApiResponse<CreateSubscriptionResponse>> createSubscription(
    String planId,
  ) async {
    try {
      debugPrint('[ApiClient] Creating subscription for plan: $planId');

      final url = Uri.parse(
        ApiConstants.getUrl(ApiConstants.createSubscription),
      );
      final body = jsonEncode({'plan_id': planId});

      final headers = await _getHeaders(includeAuth: true);
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final subscriptionResponse = CreateSubscriptionResponse.fromJson(data);

        return ApiResponse<CreateSubscriptionResponse>(
          isSuccess: true,
          data: subscriptionResponse,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to create subscription';

        return ApiResponse<CreateSubscriptionResponse>(
          isSuccess: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in createSubscription: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<CreateSubscriptionResponse>(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<CurrentSubscriptionResponse>>
  getCurrentSubscription() async {
    try {
      debugPrint('[ApiClient] Getting current subscription...');

      final url = Uri.parse(
        ApiConstants.getUrl(ApiConstants.getCurrentSubscription),
      );

      final headers = await _getHeaders(includeAuth: true);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final subscriptionResponse = CurrentSubscriptionResponse.fromJson(data);

        return ApiResponse<CurrentSubscriptionResponse>(
          isSuccess: true,
          data: subscriptionResponse,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to get current subscription';

        return ApiResponse<CurrentSubscriptionResponse>(
          isSuccess: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in getCurrentSubscription: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<CurrentSubscriptionResponse>(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<ConversationResponse>> sendMessage(File audioFile) async {
    try {
      debugPrint('[ApiClient] Sending voice message...');

      final url = Uri.parse(ApiConstants.getUrl(ApiConstants.sendMessage));

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add headers
      final headers = await _getHeaders(includeAuth: true, isMultipart: true);
      request.headers.addAll(headers);

      // Add audio file
      final audioStream = http.ByteStream(audioFile.openRead());
      final audioLength = await audioFile.length();
      final audioMultipartFile = http.MultipartFile(
        'audio',
        audioStream,
        audioLength,
        filename: audioFile.path.split('/').last,
      );
      request.files.add(audioMultipartFile);

      debugPrint('[ApiClient] Sending audio file: ${audioFile.path}');

      // Send request (no timeout - conversation API may take time for processing)
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final conversationResponse = ConversationResponse.fromJson(data);

        return ApiResponse<ConversationResponse>(
          isSuccess: true,
          data: conversationResponse,
          statusCode: response.statusCode,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['message'] as String? ??
            errorData?['error'] as String? ??
            'Failed to send message';

        // Handle specific error codes
        String finalErrorMessage = errorMessage;
        if (response.statusCode == 402) {
          finalErrorMessage =
              'Subscription required. You have exceeded the free tier limit. Please subscribe to continue.';
        } else if (response.statusCode == 400) {
          finalErrorMessage = 'Invalid audio file. Please try recording again.';
        }

        return ApiResponse<ConversationResponse>(
          isSuccess: false,
          error: finalErrorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ApiClient] Error in sendMessage: $e');
      debugPrint('[ApiClient] Stack trace: $stackTrace');
      return ApiResponse<ConversationResponse>(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }
}
