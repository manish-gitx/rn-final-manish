import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/text_styles.dart';
import '../../core/providers/bible_provider.dart';
import '../../core/utils/bible_logger.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../domain/models/bible_translation.dart';

class BibleVersionBottomSheet extends ConsumerStatefulWidget {
  const BibleVersionBottomSheet({super.key});

  @override
  ConsumerState<BibleVersionBottomSheet> createState() => _BibleVersionBottomSheetState();

  static void show(BuildContext context) {
    BibleLogger.log('[BibleVersionBottomSheet] Showing bottom sheet');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const BibleVersionBottomSheet(),
    );
  }
}

class _BibleVersionBottomSheetState extends ConsumerState<BibleVersionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BibleTranslation> _filterTranslations(List<BibleTranslation> translations) {
    if (_searchQuery.isEmpty) return translations;

    final query = _searchQuery.toLowerCase();
    return translations.where((t) =>
      t.name.toLowerCase().contains(query) ||
      t.englishName.toLowerCase().contains(query) ||
      t.shortName.toLowerCase().contains(query) ||
      (t.languageName?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bibleState = ref.watch(bibleProvider);
    final filteredTranslations = _filterTranslations(bibleState.translations ?? []);

    BibleLogger.log('[BibleVersionBottomSheet] Building. Translations: ${bibleState.translations?.length ?? 0}');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF383433),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'My Bible',
            textAlign: TextAlign.center,
            style: AppTextStyles.bottomSheetTitle,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: AppTextStyles.bibleChapterSelector.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search translations...',
              hintStyle: AppTextStyles.versionPublisher,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF4A4443),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (bibleState.isLoading)
            Expanded(
              child: ListView(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 80,
                      borderRadius: 12,
                      baseColor: const Color(0xFF4A4443),
                      highlightColor: const Color(0xFF5A5453),
                    ),
                  ),
                ),
              ),
            )
          else if (bibleState.error != null)
            Expanded(
              child: Center(
                child: Text(
                  'Error: ${bibleState.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (filteredTranslations.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No translations found',
                  style: AppTextStyles.versionPublisher,
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filteredTranslations.map(
                    (translation) => _VersionItem(
                      translation: translation,
                      isSelected: translation.id == bibleState.selectedTranslation?.id,
                      onTap: () {
                        BibleLogger.log('[BibleVersionBottomSheet] Translation selected: ${translation.name}');
                        ref.read(bibleProvider.notifier).selectTranslation(translation);
                        Navigator.pop(context);
                      },
                    ),
                  ).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionItem extends StatelessWidget {
  final BibleTranslation translation;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionItem({
    required this.translation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4443) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      translation.name,
                      style: AppTextStyles.versionName,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${translation.shortName} • ${translation.languageName ?? translation.language}',
                style: AppTextStyles.versionPublisher,
              ),
              Text(
                '${translation.numberOfBooks} books • ${translation.totalNumberOfChapters} chapters',
                style: AppTextStyles.versionPublisher.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}