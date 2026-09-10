import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/lesson_dao.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../widgets/lesson_form_sheet.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final lessonsAsync = ref.watch(lessonDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.scheduleTodayTab),
            Tab(text: l10n.scheduleTomorrowTab),
            Tab(text: l10n.scheduleWeekTab),
          ],
        ),
      ),
      body: StreamBuilder<List<LessonWithSubject>>(
        stream: lessonsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const ListSkeletonLoader();
          final lessons = snapshot.data!;
          final today = DateTime.now().weekday;
          final tomorrow = today == 7 ? 1 : today + 1;

          return TabBarView(
            controller: _tabController,
            children: [
              _DayList(
                lessons: lessons.where((l) => l.lesson.dayOfWeek == today).toList(),
                localeCode: localeCode,
              ),
              _DayList(
                lessons: lessons.where((l) => l.lesson.dayOfWeek == tomorrow).toList(),
                localeCode: localeCode,
              ),
              _WeekList(lessons: lessons, localeCode: localeCode),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LessonFormSheet.show(context, ref),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(l10n.addLesson),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  final List<LessonWithSubject> lessons;
  final String localeCode;
  const _DayList({required this.lessons, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (lessons.isEmpty) {
      return EmptyStateView(
        icon: PhosphorIconsRegular.calendarBlank,
        title: l10n.noLessonsToday,
      );
    }
    final sorted = [...lessons]..sort((a, b) => a.lesson.startTime.compareTo(b.lesson.startTime));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _LessonRow(item: sorted[index], localeCode: localeCode),
    );
  }
}

class _WeekList extends StatelessWidget {
  final List<LessonWithSubject> lessons;
  final String localeCode;
  const _WeekList({required this.lessons, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (lessons.isEmpty) {
      return EmptyStateView(
        icon: PhosphorIconsRegular.calendarBlank,
        title: l10n.scheduleEmptyTitle,
        subtitle: l10n.scheduleEmptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
      ),
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final dayOfWeek = dayIndex + 1;
        final dayLessons = lessons.where((l) => l.lesson.dayOfWeek == dayOfWeek).toList()
          ..sort((a, b) => a.lesson.startTime.compareTo(b.lesson.startTime));
        if (dayLessons.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDateUtils.weekdayName(dayOfWeek, localeCode),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...dayLessons.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _LessonRow(item: item, localeCode: localeCode),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _LessonRow extends ConsumerWidget {
  final LessonWithSubject item;
  final String localeCode;
  const _LessonRow({required this.item, required this.localeCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        onTap: () => LessonFormSheet.show(context, ref, existing: item.lesson),
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: AppRadii.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: accent, borderRadius: AppRadii.smRadius),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.subject.displayName(localeCode), style: textTheme.titleSmall),
                    if (item.lesson.room.isNotEmpty || item.lesson.teacher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [item.lesson.room, item.lesson.teacher].where((s) => s.isNotEmpty).join(' · '),
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${item.lesson.startTime} – ${item.lesson.endTime}',
                style: textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(item.subject.displayName(localeCode)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              ref.read(lessonDaoProvider).delete(item.lesson.id);
              Navigator.of(context).pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
