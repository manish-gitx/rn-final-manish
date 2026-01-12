import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../navigation/app_routes.dart';

class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  final String? title;
  final String? message;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(connectivityProvider);

    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error) {
          return ErrorView(
            title: title ?? 'Something went wrong',
            message: message ?? 'An unexpected error occurred. Please try again.',
            error: error.toString(),
            networkStatus: networkStatus,
          );
        }
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final String error;
  final NetworkStatus networkStatus;

  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.error,
    required this.networkStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = networkStatus == NetworkStatus.disconnected;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOffline ? Icons.wifi_off : Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
                semanticLabel: isOffline ? 'No internet connection' : 'Error occurred',
              ),
              const SizedBox(height: 24),
              Text(
                isOffline ? 'No Internet Connection' : title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: isOffline ? 'No internet connection' : title,
              ),
              const SizedBox(height: 16),
              Text(
                isOffline
                    ? 'Please check your internet connection and try again.'
                    : message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (!isOffline) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Technical Details:\n$error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontFamily: 'monospace',
                    ),
                    semanticsLabel: 'Technical error details: $error',
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalErrorHandler {
  static void handleError(FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  }

  static void setup() {
    FlutterError.onError = handleError;
  }
}