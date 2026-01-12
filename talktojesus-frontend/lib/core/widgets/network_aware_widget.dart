import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class NetworkAwareWidget extends ConsumerWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showBanner;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(connectivityProvider);
    final isOffline = networkStatus == NetworkStatus.disconnected;

    if (isOffline && offlineWidget != null) {
      return offlineWidget!;
    }

    return Column(
      children: [
        if (isOffline && showBanner)
          Material(
            color: Colors.red.shade700,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                    semanticLabel: 'No internet connection',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet connection',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      semanticsLabel: 'No internet connection available',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class OfflineWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const OfflineWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: theme.colorScheme.outline,
              semanticLabel: 'Offline mode',
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re offline',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              semanticsLabel: 'You are currently offline',
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Some features may not be available without an internet connection.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}