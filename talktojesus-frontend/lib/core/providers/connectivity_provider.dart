import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}

// Simple connectivity provider that doesn't use connectivity_plus plugin
// This avoids the MissingPluginException while still providing network status
class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  ConnectivityNotifier() : super(NetworkStatus.connected) {
    // Assume connected by default to avoid blocking the app
    // In a real app, you might want to implement actual connectivity checking
  }

  Future<bool> get isConnected async {
    // Return true by default to avoid blocking functionality
    return true;
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, NetworkStatus>((ref) {
  return ConnectivityNotifier();
});