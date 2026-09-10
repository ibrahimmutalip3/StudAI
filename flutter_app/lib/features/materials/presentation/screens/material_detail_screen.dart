import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/material_dao.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/ai_result_sheet.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/ai/prompts/flashcard_prompts.dart';
import '../../../../core/ai/parsers/flashcard_generation_parser.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../ai_tutor/domain/ai_tutor_launch_args.dart';
import '../../application/material_ai_controller.dart';

final _materialByIdProvider = StreamProvider.family<MaterialWithSubject?, String>((ref, id) {
  final dao = ref.watch(materialDaoProvider);
  return dao.watchAll().map((all) => all.where((m) => m.material.id == id).firstOrNull);
});

class MaterialDetailScreen extends ConsumerWidget {
  final String materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final itemAsync = ref.watch(_materialByIdProvider(materialId));

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorStateView(message: l10n.somethingWentWrong),
        data: (item) {
          if (item == null) {
            return ErrorStateView(
              message: l10n.somethingWentWrong,
              actionLabel: l10n.close,
              onAction: () => context.pop(),
            );
          }
          return _DetailBody(item: item);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final MaterialWithSubject item;
  const _DetailBody({required this.item});

  String get _content =>
      item.material.textContent.isNotEmpty ? item.material.textContent : item.material.title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: scheme.surface,
          actions: [
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(PhosphorIconsRegular.trash),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SubjectChip(subjectKey: item.subject.key, label: item.subject.displayName(localeCode)),
              const SizedBox(height: AppSpacing.md),
              Text(item.material.title, style: textTheme.headlineMedium),
              if (item.material.topic.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(item.material.topic, style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (item.material.type == StudyMaterialType.image && item.material.filePath.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadii.lgRadius,
                  child: Image.file(File(item.material.filePath), fit: BoxFit.cover),
                )
              else if (item.material.type == StudyMaterialType.pdf && item.material.filePath.isNotEmpty)
                Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: AppRadii.lgRadius,
                  child: InkWell(
                    borderRadius: AppRadii.lgRadius,
                    onTap: () => context.push(
                      '/materials/${item.material.id}/pdf',
                      extra: {
                        'filePath': item.material.filePath,
                        'title': item.material.title,
                      },
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsFill.filePdf, color: accent, size: AppIconSize.lg),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(l10n.openFile, style: textTheme.titleMedium)),
                          const Icon(PhosphorIconsRegular.caretRight),
                        ],
                      ),
                    ),
                  ),
                )
              else if (item.material.textContent.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadii.lgRadius),
                  child: Text(item.material.textContent, style: textTheme.bodyLarge),
                ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.aiTutorTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _AiActionChip(
                    icon: PhosphorIconsRegular.textAlignLeft,
                    label: l10n.materialAiSummarize,
                    onTap: () => _runAction(context, MaterialAiAction.summarize, l10n.materialAiSummarize),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.listBullets,
                    label: l10n.materialAiKeyPoints,
                    onTap: () => _runAction(context, MaterialAiAction.keyPoints, l10n.materialAiKeyPoints),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.calendarBlank,
                    label: l10n.materialAiFindDates,
                    onTap: () => _runAction(context, MaterialAiAction.findDates, l10n.materialAiFindDates),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.function,
                    label: l10n.materialAiFindFormulas,
                    onTap: () => _runAction(context, MaterialAiAction.findFormulas, l10n.materialAiFindFormulas),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.question,
                    label: l10n.materialAiQuestions,
                    onTap: () => _runAction(context, MaterialAiAction.generateQuestions, l10n.materialAiQuestions),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.cards,
                    label: l10n.materialAiFlashcards,
                    onTap: () => _generateFlashcards(context, ref),
                  ),
                  _AiActionChip(
                    icon: PhosphorIconsRegular.testTube,
                    label: l10n.materialAiTest,
                    onTap: () => context.push('/materials/tests/generate', extra: {
                      'subjectId': item.subject.id,
                      'subjectName': item.subject.displayName(localeCode),
                      'topic': item.material.topic,
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/ai-tutor',
                  extra: AiTutorLaunchArgs(
                    subjectKey: item.subject.key,
                    subjectName: item.subject.displayName(localeCode),
                    topic: item.material.topic,
                    materialExcerpt: _content,
                  ),
                ),
                icon: const Icon(PhosphorIconsRegular.sparkle),
                label: Text(l10n.materialAiAskAboutThis),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _runAction(BuildContext context, MaterialAiAction action, String title) {
    AiResultSheet.show(
      context,
      title: title,
      resultProvider: materialAiResultProvider(MaterialAiRequest(action: action, content: _content)),
    );
  }

  Future<void> _generateFlashcards(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final aiService = ref.read(aiServiceProvider);
    final locale = ref.read(localeCodeProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rawJson = await aiService.generateStructuredJson(
        systemPrompt: FlashcardPrompts.system(locale),
        userPrompt: FlashcardPrompts.userPrompt(sourceContent: _content, cardCount: 10),
      );
      final cards = FlashcardGenerationParser.parse(rawJson);
      final deckId = IdGenerator.next();
      final flashcardDao = ref.read(flashcardDaoProvider);
      await flashcardDao.upsertDeck(
        FlashcardDecksCompanion(
          id: Value(deckId),
          title: Value(item.material.title),
          subjectId: Value(item.subject.id),
        ),
      );
      for (final card in cards) {
        await flashcardDao.upsertCard(
          FlashcardsCompanion(
            id: Value(IdGenerator.next()),
            deckId: Value(deckId),
            front: Value(card.front),
            back: Value(card.back),
            subjectId: Value(item.subject.id),
          ),
        );
      }
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flashcardsCreated(cards.length))),
        );
        context.push('/materials/flashcards/$deckId/study');
      }
    } catch (e) {
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(item.material.title),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              ref.read(materialDaoProvider).deleteById(item.material.id);
              context.pop();
              context.pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AiActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: AppRadii.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.sm, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
