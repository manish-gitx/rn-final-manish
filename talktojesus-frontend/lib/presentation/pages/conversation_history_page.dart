import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/text_styles.dart';
import '../../core/enums/app_language.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../data/services/api_client.dart';
import '../../domain/models/conversation_history_model.dart';
import '../widgets/page_header.dart';

class ConversationHistoryPage extends ConsumerStatefulWidget {
  const ConversationHistoryPage({super.key});

  @override
  ConsumerState<ConversationHistoryPage> createState() =>
      _ConversationHistoryPageState();
}

class _ConversationHistoryPageState
    extends ConsumerState<ConversationHistoryPage> {
  final ApiClient _apiClient = ApiClient();
  List<ConversationHistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScreenView('Conversation History');
    });
  }

  Future<void> _load() async {
    final response = await _apiClient.getConversationHistory(limit: 50);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.isSuccess) {
        _entries = response.data ?? [];
        _error = null;
      } else {
        _error = response.error;
      }
    });
  }

  String _formatWhen(DateTime? when) {
    if (when == null) return '';
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${when.day}/${when.month}/${when.year}';
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appStateProvider).currentLanguage;

    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  PageHeader(
                    title: AppStrings.get('conversation_history', language),
                    onBackPressed: () => NavigationService.pop(),
                    heroTag: 'conversation_history_title',
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: _entries.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 140),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Text(
                                            _error ??
                                                AppStrings.get(
                                                  'history_empty',
                                                  language,
                                                ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _entries.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) =>
                                        _HistoryCard(
                                      entry: _entries[index],
                                      language: language,
                                      when: _formatWhen(
                                        _entries[index].createdAt,
                                      ),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.language,
    required this.when,
  });

  final ConversationHistoryEntry entry;
  final AppLanguage language;
  final String when;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.language.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                when,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (entry.userMessage != null && entry.userMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.get('you_said', language),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              entry.userMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
          if (entry.assistantText != null &&
              entry.assistantText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.get('jesus_said', language),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              entry.assistantText!,
              style: AppTextStyles.bibleContent.copyWith(
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
