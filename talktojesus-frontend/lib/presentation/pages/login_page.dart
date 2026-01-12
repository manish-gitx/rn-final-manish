import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/services/auth_service.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/accessibility/accessibility_utils.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/custom_toast.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  int _tapCount = 0;
  bool _showDemoButton = false;

  void _handleTitleTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5 && !_showDemoButton) {
        _showDemoButton = true;
        CustomToast.show(
          context,
          message: 'Demo account unlocked!',
          type: ToastType.success,
        );
      }
    });
  }

  Future<void> _handleDemoLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AccessibilityUtils.provideFeedback();

      // Sign in as tester account
      await ref.read(authProvider.notifier).signInAsTester();

      if (mounted) {
        final authState = ref.read(authProvider);

        if (authState.isAuthenticated && authState.user != null) {
          CustomToast.show(
            context,
            message: 'Tester account activated!',
            type: ToastType.success,
          );

          // Navigate to home after successful tester login
          await NavigationService.pushReplacementNamed(AppRoutes.home);
        } else {
          CustomToast.show(
            context,
            message: 'Tester login failed: ${authState.error ?? "Unknown error"}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('[LoginPage] Error during demo login: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Demo login failed: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AccessibilityUtils.provideFeedback();

      final result = await _authService.signInWithGoogle();

      if (result != null && mounted) {
        // Refresh auth state in provider
        ref.read(authProvider.notifier).refreshAuthStatus();

        // Show success toast
        CustomToast.show(
          context,
          message: 'Sign in successful! Welcome.',
          type: ToastType.success,
        );

        // Navigate to home/dashboard after successful login
        await NavigationService.pushReplacementNamed(AppRoutes.home);
      } else if (mounted) {
        // Show error if sign in failed (only if not cancelled)
        CustomToast.show(
          context,
          message: 'Sign in cancelled or failed. Please try again.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint('[LoginPage] Error during sign in: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Sign in failed: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image matching Jesus page
          Semantics(
            image: true,
            label: 'Background image of Jesus Christ',
            child: Transform.scale(
              scale: 1.2,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/jesus.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Centered text content
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main heading - Tappable for demo mode
                          GestureDetector(
                            onTap: _handleTitleTap,
                            child: Semantics(
                              header: true,
                              child: SizedBox(
                                width: 360,
                                child: Text(
                                  'God First, Every Day.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(
                                    color: Colors.black,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    height: 1.10,
                                    letterSpacing: -1.12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          SizedBox(
                            width: 360,
                            child: Text(
                              'Step into His presence, anytime.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sign-in buttons at bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGoogleSignInButton(),
                        if (_showDemoButton) ...[
                          const SizedBox(height: 12),
                          _buildDemoAccountButton(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: Shimmer.fromColors(
                            baseColor: const Color(0xFF6E43A6),
                            highlightColor: const Color(0xFF9B6DD6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6E43A6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Signing in...',
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Semantics(
      label: 'Sign up with Google',
      hint: 'Tap to sign up using your Google account',
      button: true,
      enabled: !_isLoading,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleGoogleSignIn,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: Colors.black.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Sign up with Google',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/svg/google_logo.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountButton() {
    return Semantics(
      label: 'Enter with demo account',
      hint: 'Tap to access the app with a demo account for testing',
      button: true,
      enabled: !_isLoading,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleDemoLogin,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E43A6), Color(0xFF9B6DD6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Center(
            child: Text(
              'Enter with Demo Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
