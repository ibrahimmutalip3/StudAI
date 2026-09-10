import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../application/statistics_controller.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(statsPeriodProvider);
    final snapshotAsync = ref.watch(statsSnapshotProvider);
    final localeCode = ref.watch(localeCodeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
        ),
        children: [
          SegmentedButton<StatsPeriod>(
            segments: [
              ButtonSegment(value: StatsPeriod.week, label: Text(l10n.statsPeriodWeek)),
              ButtonSegment(value: StatsPeriod.month, label: Text(l10n.statsPeriodMonth)),
              ButtonSegment(value: StatsPeriod.allTime, label: Text(l10n.statsPeriodAllTime)),
            ],
            selected: {period},
            onSelectionChanged: (s) => ref.read(statsPeriodProvider.notifier).state = s.first,
          ),
          const SizedBox(height: AppSpacing.xl),
          snapshotAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, st) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: ErrorStateView(message: l10n.somethingWentWrong),
            ),
            data: (stats) {
              if (stats.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: EmptyStateView(
                    icon: Icons.insights_outlined,
                    title: l10n.statsEmptyTitle,
                    subtitle: l10n.statsEmptySubtitle,
                  ),
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: l10n.statsCompletedHomework,
                          value: '${stats.completedHomework}',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          label: l10n.statsOverdueHomework,
                          value: '${stats.overdueHomework}',
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: l10n.statsCompletionRate,
                          value: '${(stats.completionRate * 100).round()}%',
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          label: l10n.statsTestsCompleted,
                          value: '${stats.testsCompleted}',
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionCard(
                    title: l10n.statsStudyTime,
                    child: Text(
                      AppDateUtils.friendlyDuration(Duration(seconds: stats.totalStudySeconds), localeCode),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (stats.studyTimeBySubject.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: l10n.statsStudyTimeBySubject,
                      child: Column(
                        children: stats.studyTimeBySubject
                            .map((s) => _SubjectTimeBar(
                                  subjectName: s.subject.displayName(localeCode),
                                  subjectKey: s.subject.key,
                                  seconds: s.seconds,
                                  maxSeconds: stats.studyTimeBySubject.first.seconds,
                                  localeCode: localeCode,
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: l10n.statsMostStudied,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: stats.studyTimeBySubject
                            .take(5)
                            .map((s) => Chip(
                                  label: Text(s.subject.displayName(localeCode)),
                                  backgroundColor: AppColors.forSubjectKey(s.subject.key).withValues(alpha: 0.14),
                                  labelStyle: TextStyle(color: AppColors.forSubjectKey(s.subject.key)),
                                  side: BorderSide.none,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadii.lgRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadii.lgRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SubjectTimeBar extends StatelessWidget {
  final String subjectName;
  final String subjectKey;
  final int seconds;
  final int maxSeconds;
  final String localeCode;

  const _SubjectTimeBar({
    required this.subjectName,
    required this.subjectKey,
    required this.seconds,
    required this.maxSeconds,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.forSubjectKey(subjectKey);
    final ratio = maxSeconds == 0 ? 0.0 : seconds / maxSeconds;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subjectName, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                AppDateUtils.friendlyDuration(Duration(seconds: seconds), localeCode),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadii.pillRadius,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}
