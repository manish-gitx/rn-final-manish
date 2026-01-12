import 'package:flutter/material.dart';
import '../../domain/models/song.dart';
import 'app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context => navigatorKey.currentContext!;
  static NavigatorState get navigator => navigatorKey.currentState!;

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    return navigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return navigator.pop<T>(result);
  }

  static Future<void> popAndPushNamed(String routeName, {Object? arguments}) async {
    navigator.pop();
    await pushNamed(routeName, arguments: arguments);
  }

  static void popUntil(String routeName) {
    navigator.popUntil(ModalRoute.withName(routeName));
  }

  static Future<void> navigateToAudioSongs() async {
    await pushNamed(AppRoutes.audioSongs);
  }

  static Future<void> navigateToAudioPlayer(Song song) async {
    await pushNamed(AppRoutes.audioPlayer, arguments: song);
  }

  static Future<void> navigateToBible() async {
    await pushNamed(AppRoutes.bible);
  }

  static Future<void> navigateToHome() async {
    await pushReplacementNamed(AppRoutes.home);
  }

  static bool canPop() {
    return navigator.canPop();
  }

  static Future<bool> willPop() async {
    if (canPop()) {
      pop();
      return false;
    }
    return true;
  }
}