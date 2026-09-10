import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../widgets/homework_card.dart';
import '../../application/homework_filter_controller.dart';

class HomeworkListScreen extends ConsumerWidget {
  const HomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final filter = ref.watch(homeworkFilterProvider);
    final homeworkAsync = ref.watch(filteredHomeworkProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeworkTitle)),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _FilterChip(
                  label: l10n.filterAll,
                  selected: filter == HomeworkFilter.all,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.all,
                ),
                _FilterChip(
                  label: l10n.filterToday,
                  selected: filter == HomeworkFilter.today,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.today,
                ),
                _FilterChip(
                  label: l10n.filterTomorrow,
                  selected: filter == HomeworkFilter.tomorrow,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.tomorrow,
                ),
                _FilterChip(
                  label: l10n.filterThisWeek,
                  selected: filter == HomeworkFilter.thisWeek,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.thisWeek,
                ),
                _FilterChip(
                  label: l10n.filterOverdue,
                  selected: filter == HomeworkFilter.overdue,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.overdue,
                ),
                _FilterChip(
                  label: l10n.filterCompleted,
                  selected: filter == HomeworkFilter.completed,
                  onTap: () => ref.read(homeworkFilterProvider.notifier).state = HomeworkFilter.completed,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: homeworkAsync.when(
              loading: () => const ListSkeletonLoader(),
              error: (err, st) => ErrorStateView(
                message: l10n.somethingWentWrong,
                actionLabel: l10n.tryAgain,
                onAction: () => ref.invalidate(filteredHomeworkProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyStateView(
                    icon: PhosphorIconsRegular.checkSquare,
                    title: l10n.noHomeworkYet,
                    actionLabel: l10n.addHomework,
                    onAction: () => context.push('/homework/new'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return HomeworkCard(
                      item: item,
                      localeCode: localeCode,
                      onTap: () => context.push('/homework/${item.homework.id}'),
                      onToggleComplete: (done) => _toggleComplete(ref, item.homework.id, done),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _AddHomeworkFab(
        onCamera: () => context.push('/homework/capture'),
        onManual: () => context.push('/homework/new'),
      ),
    );
  }

  void _toggleComplete(WidgetRef ref, String id, bool done) {
    ref.read(homeworkDaoProvider).updateStatus(
          id,
          done ? HomeworkStatus.completed : HomeworkStatus.pending,
        );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddHomeworkFab extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onManual;
  const _AddHomeworkFab({required this.onCamera, required this.onManual});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      onPressed: () => _showAddSheet(context),
      label: Text(l10n.addHomework),
      icon: const Icon(PhosphorIconsBold.plus),
    );
  }

  void _showAddSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.camera),
                title: Text(l10n.addHomeworkFromCamera),
                onTap: () {
                  Navigator.of(context).pop();
                  onCamera();
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.pencilSimple),
                title: Text(l10n.addHomeworkManually),
                onTap: () {
                  Navigator.of(context).pop();
                  onManual();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
