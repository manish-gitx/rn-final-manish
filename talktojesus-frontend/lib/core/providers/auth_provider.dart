import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if JWT token exists
      final hasToken = await _authService.isAuthenticated();

      if (hasToken) {
        // Token exists - fetch user from API
        final userModel = await _authService.getCurrentUserModel();

        if (userModel != null) {
          // User fetched successfully
          state = state.copyWith(
            user: userModel,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          // Token exists but API call failed (token might be invalid)
          state = state.copyWith(
            user: null,
            isAuthenticated: false,
            isLoading: false,
          );
        }
      } else {
        // No JWT token - user needs to login
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error checking auth status: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
        user: null,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        final user = result['user'] as UserModel;
        final isNewUser = result['isNewUser'] as bool? ?? false;
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        debugPrint(
          '[AuthProvider] Sign in successful. Is new user: $isNewUser',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign in cancelled or failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshAuthStatus() async {
    await _checkAuthStatus();
  }

  Future<void> signInAsTester() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.signInAsTester();

      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        debugPrint('[AuthProvider] Tester sign in successful');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Tester sign in failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
