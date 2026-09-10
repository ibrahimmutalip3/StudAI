import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/database/daos/lesson_dao.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Bespoke "next up" card — deliberately not a generic list-item card.
/// Uses a colored left rail matching the subject accent and a large
/// time readout, since this is the single most time-critical piece of
/// information on the Today screen.
class NextLessonCard extends StatelessWidget {
  final LessonWithSubject lesson;
  final String localeCode;

  const NextLessonCard({
    super.key,
    required this.lesson,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = AppColors.forSubjectKey(lesson.subject.key);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 88,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadii.lg),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.upNext,
                          style: textTheme.labelMedium?.copyWith(color: accent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.subject.displayName(localeCode),
                          style: textTheme.titleLarge,
                        ),
                        if (lesson.lesson.room.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.doorOpen,
                                  size: AppIconSize.sm,
                                  color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(lesson.lesson.room,
                                  style: textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    AppDateUtils.timeOnly(
                      _timeToday(lesson.lesson.startTime),
                      localeCode,
                    ),
                    style: textTheme.headlineSmall?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _timeToday(String hhmm) {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
