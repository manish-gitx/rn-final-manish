import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/user_model.dart';
import 'token_service.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final TokenService _tokenService = TokenService();
  final ApiClient _apiClient = ApiClient();
  static bool _isInitialized = false;

  SharedPreferences? _prefs;

  static const String _cachedUserKey = 'cached_user_model';

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Initialize Google Sign-In
  Future<void> _initSignIn() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize();
      _isInitialized = true;
      debugPrint('[AuthService] Google Sign-In initialized successfully.');
    }
  }

  /// Sign in with Google and authenticate with backend API
  /// Returns a map with UserModel and isNewUser flag
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    debugPrint('[AuthService] Attempting Google Sign-In...');
    try {
      await _initSignIn();

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser == null) {
        debugPrint('[AuthService] Google Sign-In cancelled by user.');

        // Track Google sign-in cancelled
        try {
          await Posthog().capture(
            eventName: 'google_sign_in_cancelled',
            properties: {'timestamp': DateTime.now().toIso8601String()},
          );
        } catch (e) {
          debugPrint('[AuthService] Failed to track cancellation: $e');
        }

        return null;
      }

      // Get authentication data
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google.');
      }

      // Call backend API to create or get user
      debugPrint('[AuthService] Calling backend API to create or get user...');
      final apiResponse = await _apiClient.createOrGetUser(idToken);

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw Exception(
          apiResponse.error ?? 'Failed to create or get user from backend',
        );
      }

      final userResponse = apiResponse.data!;
      final userModel = userResponse.user;
      final isNewUser =
          userModel.createdAt.difference(DateTime.now()).abs().inMinutes <
          5; // Approximate new user check

      // Store the backend JWT token
      if (userResponse.token != null) {
        // Check if this is a tester account
        final isTester = userModel.isTester;
        await _tokenService.saveToken(userResponse.token!, isTester: isTester);

        // Set the appropriate token in API client
        if (isTester) {
          // Use hardcoded tester token for API calls
          _apiClient.setToken(await _tokenService.getToken() ?? '');
        } else {
          _apiClient.setToken(userResponse.token!);
        }
      }

      // Cache user model locally
      await _cacheUserModel(userModel);

      debugPrint(
        '[AuthService] User authenticated successfully. Is new user: $isNewUser',
      );

      // Track successful sign-in
      try {
        await Posthog().capture(
          eventName: 'google_sign_in_success',
          properties: {
            'userId': userModel.id,
            'email': userModel.email,
            'isNewUser': isNewUser,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        debugPrint('[AuthService] Failed to track success: $e');
      }

      return {'user': userModel, 'isNewUser': isNewUser};
    } catch (error) {
      debugPrint('[AuthService] Google Sign-In failed with error: $error');
      await signOut(); // Clean up on failure
      return null;
    }
  }

  /// Cache user model to local storage
  Future<void> _cacheUserModel(UserModel user) async {
    try {
      await _init();
      await _prefs?.setString(_cachedUserKey, jsonEncode(user.toJson()));
      debugPrint('[AuthService] User model cached locally');
    } catch (e) {
      debugPrint('[AuthService] Failed to cache user model: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      debugPrint('[AuthService] Signing out...');
      await _googleSignIn.signOut();
      await _tokenService.deleteToken();
      _apiClient.clearToken();
      await _init();
      await _prefs?.remove(_cachedUserKey);
      debugPrint('[AuthService] Signed out successfully');
    } catch (error) {
      debugPrint('[AuthService] Sign out error: $error');
      rethrow;
    }
  }

  /// Check if user is authenticated (JWT-based)
  /// Returns true if JWT token exists
  Future<bool> isAuthenticated() async {
    try {
      final hasToken = await _tokenService.hasToken();
      if (hasToken) {
        // Load token into API client
        final token = await _tokenService.getToken();
        if (token != null) {
          _apiClient.setToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Error checking authentication: $e');
      return false;
    }
  }

  /// Get current user from API using JWT token
  /// Returns null if token doesn't exist or API call fails
  Future<UserModel?> getCurrentUserModel() async {
    try {
      // Check if JWT token exists
      final hasToken = await _tokenService.hasToken();
      if (!hasToken) {
        debugPrint('[AuthService] No JWT token found');
        return null;
      }

      // Load token into API client
      final token = await _tokenService.getToken();
      if (token == null) {
        debugPrint('[AuthService] JWT token is null');
        return null;
      }

      _apiClient.setToken(token);

      // Call API to get current user
      debugPrint('[AuthService] Fetching current user from API...');
      final apiResponse = await _apiClient.getCurrentUser();

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        debugPrint(
          '[AuthService] Failed to get current user: ${apiResponse.error}',
        );

        // If token is invalid (401), clear it
        if (apiResponse.statusCode == 401) {
          debugPrint('[AuthService] Token is invalid, clearing...');
          await _tokenService.deleteToken();
          _apiClient.clearToken();
          await _init();
          await _prefs?.remove(_cachedUserKey);
        }

        return null;
      }

      final userModel = apiResponse.data!;

      // Cache user model locally
      await _cacheUserModel(userModel);

      debugPrint(
        '[AuthService] Current user fetched successfully: ${userModel.email}',
      );
      return userModel;
    } catch (e) {
      debugPrint('[AuthService] Error getting current user model: $e');
      return null;
    }
  }

  /// Sign in as tester account
  /// This sets up the tester account with hardcoded JWT token
  Future<UserModel?> signInAsTester() async {
    try {
      debugPrint('[AuthService] Signing in as tester account...');

      // Save tester flag
      await _tokenService.saveToken('', isTester: true);

      // Set the hardcoded tester token in API client
      final testerToken = await _tokenService.getToken();
      if (testerToken != null) {
        _apiClient.setToken(testerToken);

        // Fetch user data from API using the tester token
        debugPrint('[AuthService] Fetching tester user data from API...');
        final apiResponse = await _apiClient.getCurrentUser();

        if (apiResponse.isSuccess && apiResponse.data != null) {
          final userModel = apiResponse.data!;

          // Cache user model locally
          await _cacheUserModel(userModel);

          debugPrint(
            '[AuthService] Tester account authenticated successfully: ${userModel.email}',
          );
          return userModel;
        } else {
          debugPrint(
            '[AuthService] Failed to fetch tester user data: ${apiResponse.error}',
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[AuthService] Error signing in as tester: $e');
      return null;
    }
  }
}
