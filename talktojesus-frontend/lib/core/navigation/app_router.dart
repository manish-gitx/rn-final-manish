import 'package:flutter/material.dart';
import '../../domain/models/song.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/jesus_page.dart';
import '../../presentation/pages/audio_songs_page.dart';
import '../../presentation/pages/audio_player_page.dart';
import '../../presentation/pages/bible_page.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return FadeSlideTransition(page: const LoginPage());

      case AppRoutes.home:
        return FadeSlideTransition(page: const JesusPage());

      case AppRoutes.audioSongs:
        return CustomSlideTransition(
          page: const AudioSongsPage(),
          beginOffset: const Offset(1.0, 0.0),
        );

      case AppRoutes.audioPlayer:
        final song = settings.arguments as Song?;
        if (song == null) {
          return _errorRoute('Song data is required');
        }
        return CustomSlideTransition(
          page: AudioPlayerPage(song: song),
          beginOffset: const Offset(1.0, 0.0),
        );

      case AppRoutes.bible:
        return CustomSlideTransition(
          page: const BiblePage(),
          beginOffset: const Offset(0.0, 1.0),
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
