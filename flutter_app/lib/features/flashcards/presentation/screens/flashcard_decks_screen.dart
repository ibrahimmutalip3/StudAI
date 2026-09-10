import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/flashcard_dao.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../application/flashcard_generation_controller.dart';

/// A deck plus a live count of how many cards it holds — computed once
/// per deck list emission rather than a separate stream per card, since
/// decks are few and cards are cheap to `watch()` and count.
final _deckCardCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final dao = ref.watch(flashcardDaoProvider);
  return dao.watchDecks().asyncExpand((decks) async* {
    final counts = <String, int>{};
    for (final deck in decks) {
      final cards = await dao.watchCardsInDeck(deck.id).first;
      counts[deck.id] = cards.length;
    }
    yield counts;
  });
});

class FlashcardDecksScreen extends ConsumerWidget {
  const FlashcardDecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final decksAsync = ref.watch(flashcardDaoProvider).watchDecks();
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();
    final countsAsync = ref.watch(_deckCardCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.flashcardsTitle)),
      body: StreamBuilder<List<Subject>>(
        stream: subjectsAsync,
        builder: (context, subjectSnap) {
          final subjectById = {
            for (final s in subjectSnap.data ?? const <Subject>[]) s.id: s,
          };
          return StreamBuilder<List<FlashcardDeck>>(
            stream: decksAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const ListSkeletonLoader();
              final decks = snapshot.data!;
              if (decks.isEmpty) {
                return EmptyStateView(
                  icon: PhosphorIconsRegular.cards,
                  title: l10n.flashcardsEmptyTitle,
                  subtitle: l10n.flashcardsEmptySubtitle,
                  actionLabel: l10n.newDeck,
                  onAction: () => _showCreateSheet(context, ref),
                );
              }
              final counts = countsAsync.valueOrNull ?? const <String, int>{};
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.92,
                ),
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final subject = deck.subjectId != null ? subjectById[deck.subjectId] : null;
                  return _DeckCard(
                    deck: deck,
                    subject: subject,
                    localeCode: localeCode,
                    cardCount: counts[deck.id] ?? 0,
                    onTap: () => context.push('/materials/flashcards/${deck.id}/study'),
                    onDelete: () => _confirmDelete(context, ref, deck),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(PhosphorIconsBold.plus),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.newDeck, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(PhosphorIconsRegular.pencilSimple),
                title: Text(l10n.addCard),
                onTap: () {
                  Navigator.of(context).pop();
                  _createEmptyDeck(context, ref);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(PhosphorIconsRegular.sparkle),
                title: Text(l10n.generateFromTopic),
                onTap: () {
                  Navigator.of(context).pop();
                  _showGenerateFromTopicSheet(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createEmptyDeck(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newDeck),
        content: TextField(
          controller: titleController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.deckTitleHint),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => context.pop(titleController.text.trim()),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    final deckId = IdGenerator.next();
    await ref.read(flashcardDaoProvider).upsertDeck(
          FlashcardDecksCompanion(id: Value(deckId), title: Value(title)),
        );
    if (context.mounted) {
      context.push('/materials/flashcards/$deckId/study');
    }
  }

  void _showGenerateFromTopicSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GenerateFromTopicSheet(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FlashcardDeck deck) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(deck.title),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              ref.read(flashcardDaoProvider).deleteDeck(deck.id);
              context.pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final FlashcardDeck deck;
  final Subject? subject;
  final String localeCode;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.subject,
    required this.localeCode,
    required this.cardCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = subject != null ? AppColors.forSubjectKey(subject!.key) : AppColors.subjectOther;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: AppRadii.smRadius,
                    ),
                    child: Icon(PhosphorIconsFill.cards, color: accent, size: AppIconSize.sm),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: AppRadii.smRadius,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(PhosphorIconsRegular.trash, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                deck.title,
                style: textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cardsCount(cardCount),
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateFromTopicSheet extends ConsumerStatefulWidget {
  const _GenerateFromTopicSheet();

  @override
  ConsumerState<_GenerateFromTopicSheet> createState() => _GenerateFromTopicSheetState();
}

class _GenerateFromTopicSheetState extends ConsumerState<_GenerateFromTopicSheet> {
  final _topicController = TextEditingController();
  String? _subjectId;
  bool _generating = false;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    final topic = _topicController.text.trim();
    if (topic.isEmpty || _subjectId == null) return;

    setState(() => _generating = true);
    try {
      final subject = await ref.read(subjectDaoProvider).getById(_subjectId!);
      final deckId = await ref.read(flashcardGenerationControllerProvider).generateFromTopic(
            subjectId: _subjectId!,
            subjectName: subject?.displayName(ref.read(localeCodeProvider)) ?? '',
            topic: topic,
          );
      if (mounted) {
        context.pop();
        context.push('/materials/flashcards/$deckId/study');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();
    final localeCode = ref.watch(localeCodeProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.generateFromTopic, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<List<Subject>>(
              stream: subjectsAsync,
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? const <Subject>[];
                return DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: InputDecoration(labelText: l10n.testSubject),
                  items: subjects
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName(localeCode))))
                      .toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _topicController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.testTopic, hintText: l10n.testTopicHint),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: (_generating || _subjectId == null || _topicController.text.trim().isEmpty)
                  ? null
                  : _generate,
              child: _generating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.generateFromTopic),
            ),
          ],
        ),
      ),
    );
  }
}
