import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../homework/presentation/widgets/homework_card.dart';
import '../../application/today_controller.dart';
import '../widgets/today_greeting_header.dart';
import '../widgets/next_lesson_card.dart';
import '../widgets/today_horizontal_cards.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(todaySnapshotProvider);
    final settingsAsync = ref.watch(settingsDaoProvider).watch();
    final localeCode = ref.watch(localeCodeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<UserSettingsTableData>(
          stream: settingsAsync,
          builder: (context, settingsSnap) {
            final displayName = settingsSnap.data?.displayName ?? '';

            return snapshotAsync.when(
              loading: () => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                    ),
                    child: TodayGreetingHeader(
                      displayName: displayName,
                      onSearchTap: () => context.push('/search'),
                      onProfileTap: () => context.go('/profile'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Expanded(child: ListSkeletonLoader()),
                ],
              ),
              error: (err, st) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                    ),
                    child: TodayGreetingHeader(
                      displayName: displayName,
                      onSearchTap: () => context.push('/search'),
                      onProfileTap: () => context.go('/profile'),
                    ),
                  ),
                  Expanded(
                    child: ErrorStateView(
                      message: l10n.somethingWentWrong,
                      actionLabel: l10n.tryAgain,
                      onAction: () => ref.invalidate(todaySnapshotProvider),
                    ),
                  ),
                ],
              ),
              data: (snapshot) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: TodayGreetingHeader(
                        displayName: displayName,
                        onSearchTap: () => context.push('/search'),
                        onProfileTap: () => context.go('/profile'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: _FocusModeBanner(
                        onTap: () => context.push('/focus/setup'),
                      ),
                    ),
                  ),
                  if (snapshot.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        icon: PhosphorIconsRegular.confetti,
                        title: l10n.allCaughtUp,
                        subtitle: l10n.todayEmptySubtitle,
                        actionLabel: l10n.addHomework,
                        onAction: () => context.push('/homework/new'),
                      ),
                    )
                  else ...[
                    if (snapshot.nextLesson != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: NextLessonCard(
                            lesson: snapshot.nextLesson!,
                            localeCode: localeCode,
                          ),
                        ),
                      ),
                    if (snapshot.overdue.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: l10n.filterOverdue),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        sliver: SliverList.separated(
                          itemCount: snapshot.overdue.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = snapshot.overdue[index];
                            return HomeworkCard(
                              item: item,
                              localeCode: localeCode,
                              onTap: () => context.push('/homework/${item.homework.id}'),
                              onToggleComplete: (done) => _toggleComplete(ref, item.homework.id, done),
                            );
                          },
                        ),
                      ),
                    ],
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                          title: l10n.homeworkDueToday,
                          actionLabel: snapshot.dueToday.isNotEmpty ? l10n.viewAll : null,
                          onAction: () => context.go('/homework'),
                        ),
                      ),
                    ),
                    if (snapshot.dueToday.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: _InlineEmptyRow(text: l10n.todayEmptyTitle),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        sliver: SliverList.separated(
                          itemCount: snapshot.dueToday.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final item = snapshot.dueToday[index];
                            return HomeworkCard(
                              item: item,
                              localeCode: localeCode,
                              onTap: () => context.push('/homework/${item.homework.id}'),
                              onToggleComplete: (done) => _toggleComplete(ref, item.homework.id, done),
                            );
                          },
                        ),
                      ),
                    if (snapshot.upcomingTests.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: l10n.todayUpcomingTests),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 118,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: snapshot.upcomingTests.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = snapshot.upcomingTests[index];
                              return TestPreviewCard(
                                item: item,
                                localeCode: localeCode,
                                onTap: () => context.push('/materials/tests/${item.test.id}/take'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (snapshot.reviewSuggestions.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: l10n.todayReviewMaterials),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 118,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: snapshot.reviewSuggestions.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = snapshot.reviewSuggestions[index];
                              return MaterialPreviewCard(
                                item: item,
                                localeCode: localeCode,
                                onTap: () => context.push('/materials/${item.material.id}'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.huge)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleComplete(WidgetRef ref, String homeworkId, bool done) {
    ref.read(homeworkDaoProvider).updateStatus(
          homeworkId,
          done ? HomeworkStatus.completed : HomeworkStatus.pending,
        );
  }
}

class _FocusModeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _FocusModeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Material(
        color: scheme.primary,
        borderRadius: AppRadii.lgRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.onPrimary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsFill.timer, color: scheme.onPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.startFocusSession,
                    style: textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                  ),
                ),
                Icon(PhosphorIconsBold.arrowRight, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineEmptyRow extends StatelessWidget {
  final String text;
  const _InlineEmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
