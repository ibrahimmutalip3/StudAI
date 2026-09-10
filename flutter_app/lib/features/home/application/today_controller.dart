import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dao_providers.dart';
import '../../../core/database/daos/homework_dao.dart';
import '../../../core/database/daos/lesson_dao.dart';
import '../../../core/database/daos/test_dao.dart';
import '../../../core/database/daos/material_dao.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Aggregated snapshot the Today screen renders from. Kept as a single
/// derived provider (rather than five separate `.watch()` calls in the
/// widget tree) so the screen has one loading/error boundary instead of
/// five independently-flickering ones.
class TodaySnapshot {
  final List<HomeworkWithSubject> dueToday;
  final List<HomeworkWithSubject> overdue;
  final LessonWithSubject? nextLesson;
  final List<LessonWithSubject> todaysLessons;
  final List<TestWithSubject> upcomingTests;
  final List<MaterialWithSubject> reviewSuggestions;

  const TodaySnapshot({
    required this.dueToday,
    required this.overdue,
    required this.nextLesson,
    required this.todaysLessons,
    required this.upcomingTests,
    required this.reviewSuggestions,
  });

  bool get isEmpty =>
      dueToday.isEmpty &&
      overdue.isEmpty &&
      todaysLessons.isEmpty &&
      upcomingTests.isEmpty;
}

final todaySnapshotProvider = StreamProvider<TodaySnapshot>((ref) {
  final homeworkDao = ref.watch(homeworkDaoProvider);
  final lessonDao = ref.watch(lessonDaoProvider);
  final testDao = ref.watch(testDaoProvider);
  final materialDao = ref.watch(materialDaoProvider);

  final todayWeekday = DateTime.now().weekday;

  return homeworkDao.watchAll().asyncMap((allHomework) async {
    final dueToday = allHomework
        .where((h) => AppDateUtils.isToday(h.homework.deadline))
        .toList();
    final overdue =
        allHomework.where((h) => h.homework.status == HomeworkStatus.overdue).toList();

    final lessons = await lessonDao.watchForDay(todayWeekday).first;
    final now = DateTime.now();
    LessonWithSubject? next;
    for (final lesson in lessons) {
      final parts = lesson.lesson.startTime.split(':');
      final lessonTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (lessonTime.isAfter(now)) {
        next = lesson;
        break;
      }
    }

    final tests = await testDao.watchAll().first;
    final upcomingTests = tests
        .where((t) => t.test.lastTakenAt == null)
        .take(3)
        .toList();

    final materials = await materialDao.watchAll().first;
    // "Worth reviewing": materials not touched recently, oldest first —
    // a simple, honest heuristic (no fake spaced-repetition scheduling
    // claims; see DESIGN.md non-negotiables on fake functionality).
    final reviewSuggestions = materials.reversed.take(3).toList();

    return TodaySnapshot(
      dueToday: dueToday,
      overdue: overdue,
      nextLesson: next,
      todaysLessons: lessons,
      upcomingTests: upcomingTests,
      reviewSuggestions: reviewSuggestions,
    );
  });
});
