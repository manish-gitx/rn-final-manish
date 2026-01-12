import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/audio_player_repository.dart';
import '../../data/repositories/mock_audio_player_repository.dart';
import '../controllers/audio_player_controller.dart';
import '../widgets/page_header.dart';
import '../widgets/audio_player/album_art_widget.dart';
import '../widgets/audio_player/song_info_widget.dart';
import '../widgets/audio_player/progress_bar_widget.dart';
import '../widgets/audio_player/player_controls_widget.dart';
import '../../core/constants/audio_player_constants.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/accessibility/accessibility_utils.dart';
import '../../core/providers/analytics_provider.dart';

class AudioPlayerPage extends ConsumerStatefulWidget {
  final Song song;

  const AudioPlayerPage({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends ConsumerState<AudioPlayerPage> {
  late final AudioPlayerRepository _audioPlayerRepository;
  late final AudioPlayerController _audioPlayerController;

  @override
  void initState() {
    super.initState();
    _audioPlayerRepository = MockAudioPlayerRepository();
    _audioPlayerController = AudioPlayerController(_audioPlayerRepository);

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScreenView('Audio Player Page');
    });
  }

  @override
  void dispose() {
    _audioPlayerController.dispose();
    super.dispose();
  }

  Widget _buildPlayerContent() {
    if (_audioPlayerController.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _audioPlayerController.errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                AccessibilityUtils.provideFeedback();
                _audioPlayerController.setAudioSource('');
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 28),
        AlbumArtWidget(
          imageUrl: widget.song.imageUrl,
        ),
        const SizedBox(height: 28),
        SongInfoWidget(song: widget.song),
        const SizedBox(height: 18),
        ProgressBarWidget(
          currentPosition: _audioPlayerController.currentPosition,
          totalDuration: _audioPlayerController.totalDuration,
          onSeek: (position) {
            ref.read(analyticsServiceProvider).trackAudioSeek(position, widget.song.title);
            _audioPlayerController.seekToPosition(position);
          },
          formatDuration: _audioPlayerController.formatDuration,
        ),
        const SizedBox(height: 28),
        PlayerControlsWidget(
          isPlaying: _audioPlayerController.isPlaying,
          onPlayPause: () {
            ref.read(analyticsServiceProvider).trackAudioPlayPause(
              !_audioPlayerController.isPlaying,
              widget.song.title,
            );
            _audioPlayerController.togglePlayPause();
          },
          onPrevious: () {
            ref.read(analyticsServiceProvider).trackAudioSkip('previous', widget.song.title);
            // TODO: Implement previous song functionality
          },
          onNext: () {
            ref.read(analyticsServiceProvider).trackAudioSkip('next', widget.song.title);
            // TODO: Implement next song functionality
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage(AudioPlayerConstants.backgroundImagePath),
                  fit: BoxFit.cover,
                ),
                color: AudioPlayerConstants.backgroundOverlayColor.withValues(
                  alpha: AudioPlayerConstants.backgroundOverlayOpacity,
                ),
              ),
            ),
          ),
          // Content with proper padding
          SafeArea(
            child: Padding(
              padding: AudioPlayerConstants.pageHorizontalPadding,
              child: Column(
                children: [
                  PageHeader(
                    title: 'Jesus Songs',
                    onBackPressed: () => NavigationService.pop(),
                    heroTag: 'audio_player_title',
                  ),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _audioPlayerController,
                      builder: (context, child) => _buildPlayerContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}