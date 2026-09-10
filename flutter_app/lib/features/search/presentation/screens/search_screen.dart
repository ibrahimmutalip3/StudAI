import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../homework/presentation/widgets/homework_card.dart';
import '../../application/search_controller.dart' as search;

/// Global search across every locally-stored content type (product spec
/// §22): homework, notes, materials, flashcard decks, tests, and saved
/// AI responses. Reached from Today, the Materials hub, and the app
/// bar's search action — never a destination in the bottom nav itself.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Autofocus without the keyboard covering an already-typed query on
    // hot-restart/back-navigation into this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final query = ref.watch(search.searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.pillRadius,
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.magnifyingGlass, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      ref.read(search.searchQueryProvider.notifier).state = value,
                ),
              ),
              if (query.isNotEmpty)
                InkWell(
                  onTap: () {
                    _controller.clear();
                    ref.read(search.searchQueryProvider.notifier).state = '';
                  },
                  borderRadius: AppRadii.pillRadius,
                  child: Icon(PhosphorIconsFill.xCircle, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
      body: query.isEmpty
          ? EmptyStateView(
              icon: PhosphorIconsRegular.magnifyingGlass,
              title: l10n.searchEmptyTitle,
              subtitle: l10n.searchEmptySubtitle,
            )
          : _SearchResultsView(query: query),
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  final String query;
  const _SearchResultsView({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(search.searchResultsProvider);
    final localeCode = ref.watch(localeCodeProvider);

    return resultsAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (err, st) => ErrorStateView(message: l10n.somethingWentWrong),
      data: (results) {
        if (results.isEmpty) {
          return EmptyStateView(
            icon: PhosphorIconsRegular.magnifyingGlass,
            title: l10n.searchNoResults(query),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
          ),
          children: [
            if (results.homework.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionHomework,
                children: results.homework
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: HomeworkCard(
                            item: h,
                            localeCode: localeCode,
                            onTap: () => context.push('/homework/${h.homework.id}'),
                          ),
                        ))
                    .toList(),
              ),
            if (results.notes.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionNotes,
                children: results.notes
                    .map((n) => _SimpleResultTile(
                          icon: PhosphorIconsRegular.notePencil,
                          title: n.title.isEmpty ? l10n.untitled : n.title,
                          subtitle: n.content,
                          onTap: () => context.push('/materials/notes/${n.id}'),
                        ))
                    .toList(),
              ),
            if (results.materials.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionMaterials,
                children: results.materials
                    .map((m) => _SimpleResultTile(
                          icon: PhosphorIconsRegular.stack,
                          title: m.title,
                          subtitle: m.topic,
                          onTap: () => context.push('/materials/${m.id}'),
                        ))
                    .toList(),
              ),
            if (results.flashcardDecks.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionFlashcards,
                children: results.flashcardDecks
                    .map((d) => _SimpleResultTile(
                          icon: PhosphorIconsRegular.cards,
                          title: d.title,
                          onTap: () => context.push('/materials/flashcards/${d.id}/study'),
                        ))
                    .toList(),
              ),
            if (results.tests.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionTests,
                children: results.tests
                    .map((t) => _SimpleResultTile(
                          icon: PhosphorIconsRegular.testTube,
                          title: t.test.title,
                          subtitle: t.test.topic,
                          onTap: () => context.push('/materials/tests/${t.test.id}/take'),
                        ))
                    .toList(),
              ),
            if (results.savedResponses.isNotEmpty)
              _ResultSection(
                title: l10n.searchSectionSaved,
                children: results.savedResponses
                    .map((r) => _SimpleResultTile(
                          icon: PhosphorIconsRegular.sparkle,
                          title: r.title,
                          subtitle: r.content,
                        ))
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ResultSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          ...children,
        ],
      ),
    );
  }
}

class _SimpleResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SimpleResultTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.subjectOther.withValues(alpha: 0.14),
                    borderRadius: AppRadii.smRadius,
                  ),
                  child: Icon(icon, color: AppColors.subjectOther, size: AppIconSize.md),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(PhosphorIconsRegular.caretRight, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
