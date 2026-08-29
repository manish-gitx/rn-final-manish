import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/api_song_repository.dart';
import '../../data/repositories/mock_song_repository.dart';
import '../widgets/song_list_item.dart';
import '../widgets/page_header.dart';
import '../widgets/song_list_item_shimmer.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/providers/analytics_provider.dart';

class AudioSongsPage extends ConsumerStatefulWidget {
  const AudioSongsPage({super.key});

  @override
  ConsumerState<AudioSongsPage> createState() => _AudioSongsPageState();
}

class _AudioSongsPageState extends ConsumerState<AudioSongsPage> {
  final SongRepository _songRepository = ApiSongRepository();
  final SongRepository _bundledSongRepository = MockSongRepository();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScreenView('Audio Songs Page');
    });
  }

  Future<void> _loadSongs() async {
    try {
      var songs = await _songRepository.getAllSongs();
      // Fall back to the bundled offline hymn library so the player still has
      // something to play when the backend is unreachable or returns nothing.
      if (songs.isEmpty) {
        songs = await _bundledSongRepository.getAllSongs();
      }
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading songs: $e');
      try {
        final songs = await _bundledSongRepository.getAllSongs();
        if (!mounted) return;
        setState(() {
          _songs = songs;
          _error = null;
          _isLoading = false;
        });
      } catch (fallbackError) {
        if (!mounted) return;
        setState(() {
          _error = 'Could not load songs. Pull down to retry.';
          _isLoading = false;
        });
        debugPrint('Error loading bundled songs: $fallbackError');
      }
    }
  }

  Future<void> _refreshSongs() async {
    await _loadSongs();
  }

  void _onSongTap(Song song) {
    // Track song selection
    ref.read(analyticsServiceProvider).trackAudioSongSelected(
      song.title,
      _songs.indexOf(song),
    );
    ref.read(analyticsServiceProvider).trackNavigation('Audio Songs', 'Audio Player');
    NavigationService.navigateToAudioPlayer(song);
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error ?? 'No songs yet. Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ),
      ),
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
                  image: AssetImage('assets/images/jesus_backdrop.png'),
                  fit: BoxFit.cover,
                ),
                color: Colors.black.withValues(alpha: 0.70),
              ),
            ),
          ),
          // Content with proper padding
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  PageHeader(
                    title: 'Jesus Songs',
                    onBackPressed: () => NavigationService.pop(),
                    heroTag: 'jesus_songs_title',
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _isLoading
                        ? const SingleChildScrollView(
                            child: SongListShimmer(),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshSongs,
                            child: SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              child: _songs.isEmpty
                                  ? _buildEmptyState()
                                  : Column(
                                      children: _songs
                                          .map((song) => SongListItem(
                                                song: song,
                                                onTap: () => _onSongTap(song),
                                              ))
                                          .toList(),
                                    ),
                            ),
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