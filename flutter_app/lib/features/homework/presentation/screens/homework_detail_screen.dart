import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/homework_dao.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../ai_tutor/domain/ai_tutor_launch_args.dart';

final _homeworkByIdProvider =
    StreamProvider.family<HomeworkWithSubject?, String>((ref, id) {
  final dao = ref.watch(homeworkDaoProvider);
  return dao.watchAll().map(
        (all) => all.where((h) => h.homework.id == id).firstOrNull,
      );
});

class HomeworkDetailScreen extends ConsumerWidget {
  final String homeworkId;
  const HomeworkDetailScreen({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final itemAsync = ref.watch(_homeworkByIdProvider(homeworkId));

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorStateView(message: l10n.somethingWentWrong),
        data: (item) {
          if (item == null) {
            return Center(
              child: ErrorStateView(
                message: l10n.somethingWentWrong,
                actionLabel: l10n.close,
                onAction: () => context.pop(),
              ),
            );
          }
          return _DetailBody(item: item, localeCode: localeCode);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final HomeworkWithSubject item;
  final String localeCode;
  const _DetailBody({required this.item, required this.localeCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final homework = item.homework;
    final isCompleted = homework.status == HomeworkStatus.completed;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return Hero(
      tag: 'homework-${homework.id}',
      child: Material(
        color: scheme.surface,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: scheme.surface,
              actions: [
                IconButton(
                  onPressed: () => context.push('/homework/${homework.id}/edit'),
                  icon: const Icon(PhosphorIconsRegular.pencilSimple),
                ),
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
                  SubjectChip(
                    subjectKey: item.subject.key,
                    label: item.subject.displayName(localeCode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(homework.title, style: textTheme.headlineMedium),
                  if (homework.topic.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(homework.topic, style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadii.lgRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsRegular.clock, color: accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.deadline, style: textTheme.labelMedium),
                              Text(
                                AppDateUtils.dateAndTime(homework.deadline, localeCode),
                                style: textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (homework.description.isNotEmpty) ...[
                    Text(l10n.homeworkTitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(homework.description, style: textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => ref.read(homeworkDaoProvider).updateStatus(
                                homework.id,
                                isCompleted ? HomeworkStatus.pending : HomeworkStatus.completed,
                              ),
                          icon: Icon(isCompleted ? PhosphorIconsRegular.arrowCounterClockwise : PhosphorIconsBold.check),
                          label: Text(isCompleted ? l10n.statusPending : l10n.statusCompleted),
                          style: FilledButton.styleFrom(
                            backgroundColor: isCompleted ? scheme.surfaceContainerHigh : AppColors.success,
                            foregroundColor: isCompleted ? scheme.onSurface : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/ai-tutor',
                      extra: AiTutorLaunchArgs(
                        subjectKey: item.subject.key,
                        subjectName: item.subject.displayName(localeCode),
                        topic: homework.topic,
                        homeworkText: homework.description.isNotEmpty
                            ? homework.description
                            : homework.title,
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.sparkle),
                    label: Text(l10n.aiTutorTitle),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(item.homework.title),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              ref.read(homeworkDaoProvider).delete(item.homework.id);
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
