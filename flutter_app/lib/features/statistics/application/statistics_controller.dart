import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/providers/dao_providers.dart';

enum StatsPeriod { week, month, allTime }

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.week);

class SubjectStudyTime {
  final Subject subject;
  final int seconds;
  const SubjectStudyTime({required this.subject, required this.seconds});
}

class StatsSnapshot {
  final int completedHomework;
  final int overdueHomework;
  final double completionRate; // 0..1
  final int totalStudySeconds;
  final List<SubjectStudyTime> studyTimeBySubject;
  final int testsCompleted;
  final bool isEmpty;

  const StatsSnapshot({
    required this.completedHomework,
    required this.overdueHomework,
    required this.completionRate,
    required this.totalStudySeconds,
    required this.studyTimeBySubject,
    required this.testsCompleted,
    required this.isEmpty,
  });
}

(DateTime, DateTime) _rangeFor(StatsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case StatsPeriod.week:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return (start, start.add(const Duration(days: 7)));
    case StatsPeriod.month:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return (start, end);
    case StatsPeriod.allTime:
      return (DateTime(2000), now.add(const Duration(days: 1)));
  }
}

final statsSnapshotProvider = StreamProvider<StatsSnapshot>((ref) {
  final period = ref.watch(statsPeriodProvider);
  final homeworkDao = ref.watch(homeworkDaoProvider);
  final testDao = ref.watch(testDaoProvider);
  final studySessionDao = ref.watch(studySessionDaoProvider);
  final subjectDao = ref.watch(subjectDaoProvider);

  final (start, end) = _rangeFor(period);

  return homeworkDao.watchAll().asyncMap((allHomework) async {
    final inRange = allHomework.where((h) {
      final ref = h.homework.completedAt ?? h.homework.createdAt;
      return ref.isAfter(start) && ref.isBefore(end);
    }).toList();

    final completed = inRange.where((h) => h.homework.status == HomeworkStatus.completed).length;
    final overdue = allHomework.where((h) => h.homework.status == HomeworkStatus.overdue).length;
    final completionRate = inRange.isEmpty ? 0.0 : completed / inRange.length;

    final secondsBySubject = await studySessionDao.secondsBySubject(start, end);
    final subjects = await subjectDao.watchAll().first;
    final subjectById = {for (final s in subjects) s.id: s};

    final studyTimeBySubject = secondsBySubject.entries
        .where((e) => e.value > 0 && subjectById.containsKey(e.key))
        .map((e) => SubjectStudyTime(subject: subjectById[e.key]!, seconds: e.value))
        .toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));

    final totalStudySeconds = secondsBySubject.values.fold<int>(0, (sum, s) => sum + s);

    final allTests = await testDao.watchAll().first;
    final testsCompleted = allTests
        .where((t) => t.test.lastTakenAt != null && t.test.lastTakenAt!.isAfter(start) && t.test.lastTakenAt!.isBefore(end))
        .length;

    return StatsSnapshot(
      completedHomework: completed,
      overdueHomework: overdue,
      completionRate: completionRate,
      totalStudySeconds: totalStudySeconds,
      studyTimeBySubject: studyTimeBySubject,
      testsCompleted: testsCompleted,
      isEmpty: completed == 0 && overdue == 0 && totalStudySeconds == 0 && testsCompleted == 0,
    );
  });
});
