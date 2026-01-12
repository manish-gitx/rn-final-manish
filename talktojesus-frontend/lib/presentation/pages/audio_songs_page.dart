import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/song.dart';
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
  final MockSongRepository _songRepository = MockSongRepository();
  List<Song> _songs = [];
  bool _isLoading = true;

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
      final songs = await _songRepository.getAllSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading songs: $e');
    }
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
                        : SingleChildScrollView(
                            child: Column(
                              children: _songs
                                  .map((song) => SongListItem(
                                        song: song,
                                        onTap: () => _onSongTap(song),
                                      ))
                                  .toList(),
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