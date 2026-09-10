import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/homework_dao.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// The single card representation of a homework item, shared between
/// Today, Homework list, and search results so status/priority/subject
/// visuals never drift between screens. Wrapped in a [Hero] so tapping
/// through to detail can morph-transition (see DESIGN.md Motion
/// signature).
class HomeworkCard extends StatelessWidget {
  final HomeworkWithSubject item;
  final String localeCode;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggleComplete;

  const HomeworkCard({
    super.key,
    required this.item,
    required this.localeCode,
    required this.onTap,
    this.onToggleComplete,
  });

  Color _priorityColor(BuildContext context, HomeworkPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    switch (priority) {
      case HomeworkPriority.high:
        return AppColors.danger;
      case HomeworkPriority.medium:
        return AppColors.warning;
      case HomeworkPriority.low:
        return scheme.onSurfaceVariant;
    }
  }

  String _priorityLabel(AppLocalizations l10n, HomeworkPriority priority) {
    switch (priority) {
      case HomeworkPriority.high:
        return l10n.priorityHigh;
      case HomeworkPriority.medium:
        return l10n.priorityMedium;
      case HomeworkPriority.low:
        return l10n.priorityLow;
    }
  }

  String _deadlineLabel(AppLocalizations l10n) {
    final deadline = item.homework.deadline;
    if (item.homework.status == HomeworkStatus.overdue) {
      final diff = DateTime.now().difference(deadline);
      return l10n.overdueBy(AppDateUtils.friendlyDuration(diff, localeCode));
    }
    if (AppDateUtils.isToday(deadline)) {
      return l10n.atTime(AppDateUtils.timeOnly(deadline, localeCode));
    }
    if (AppDateUtils.isTomorrow(deadline)) {
      return '${l10n.filterTomorrow}, ${AppDateUtils.timeOnly(deadline, localeCode)}';
    }
    return AppDateUtils.dateAndTime(deadline, localeCode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final homework = item.homework;
    final isCompleted = homework.status == HomeworkStatus.completed;
    final isOverdue = homework.status == HomeworkStatus.overdue;

    return Hero(
      tag: 'homework-${homework.id}',
      flightShuttleBuilder: (_, __, ___, ____, _____) =>
          Material(color: Colors.transparent, child: _buildCard(context, scheme, textTheme, l10n, homework, isCompleted, isOverdue)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgRadius,
          child: _buildCard(context, scheme, textTheme, l10n, homework, isCompleted, isOverdue),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    AppLocalizations l10n,
    Homework homework,
    bool isCompleted,
    bool isOverdue,
  ) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
        border: isOverdue
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onToggleComplete != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
              child: GestureDetector(
                onTap: () => onToggleComplete!(!isCompleted),
                child: AnimatedContainer(
                  duration: AppMotion.standard,
                  curve: AppMotion.spring,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? AppColors.success : scheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SubjectChip(
                      subjectKey: homework.subjectId,
                      label: item.subject.displayName(localeCode),
                      dense: true,
                    ),
                    const Spacer(),
                    PriorityTag(
                      label: _priorityLabel(l10n, homework.priority),
                      color: _priorityColor(context, homework.priority),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  homework.title,
                  style: textTheme.titleMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      isOverdue ? PhosphorIconsRegular.clockCountdown : PhosphorIconsRegular.clock,
                      size: AppIconSize.sm,
                      color: isOverdue ? AppColors.danger : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _deadlineLabel(l10n),
                      style: textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.danger : scheme.onSurfaceVariant,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
