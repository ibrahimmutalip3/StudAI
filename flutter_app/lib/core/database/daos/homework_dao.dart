import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'homework_dao.g.dart';

@DriftAccessor(tables: [Homeworks, Subjects])
class HomeworkDao extends DatabaseAccessor<AppDatabase>
    with _$HomeworkDaoMixin {
  HomeworkDao(super.db);

  /// Full join stream: homework + its subject, ordered by deadline.
  /// Statuses are recomputed on read (see [_withComputedStatus]) so an
  /// item that has passed its deadline shows as overdue without needing
  /// a background job.
  Stream<List<HomeworkWithSubject>> watchAll() {
    final query = select(homeworks).join([
      innerJoin(subjects, subjects.id.equalsExp(homeworks.subjectId)),
    ])
      ..orderBy([OrderingTerm.asc(homeworks.deadline)]);

    return query.watch().map((rows) => rows
        .map((row) => HomeworkWithSubject(
              homework: _withComputedStatus(row.readTable(homeworks)),
              subject: row.readTable(subjects),
            ))
        .toList());
  }

  Stream<List<HomeworkWithSubject>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return watchAll().map((list) => list
        .where((hw) =>
            hw.homework.deadline.isAfter(startOfDay) &&
            hw.homework.deadline.isBefore(endOfDay))
        .toList());
  }

  Stream<List<HomeworkWithSubject>> watchOverdue() {
    return watchAll().map((list) => list
        .where((hw) => hw.homework.status == HomeworkStatus.overdue)
        .toList());
  }

  Stream<List<HomeworkWithSubject>> watchUpcoming({int days = 7}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return watchAll().map((list) => list
        .where((hw) =>
            hw.homework.deadline.isAfter(now) &&
            hw.homework.deadline.isBefore(cutoff) &&
            hw.homework.status != HomeworkStatus.completed)
        .toList());
  }

  Future<Homework?> getById(String id) async {
    final row = await (select(homeworks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _withComputedStatus(row);
  }

  Future<void> upsert(HomeworksCompanion homework) {
    return into(homeworks).insertOnConflictUpdate(homework);
  }

  Future<void> updateStatus(String id, HomeworkStatus status) {
    return (update(homeworks)..where((t) => t.id.equals(id))).write(
      HomeworksCompanion(
        status: Value(status),
        completedAt: Value(
          status == HomeworkStatus.completed ? DateTime.now() : null,
        ),
      ),
    );
  }

  Future<void> delete(String id) {
    return (delete(homeworks)..where((t) => t.id.equals(id))).go();
  }

  /// Homework whose deadline has passed but which is not marked completed
  /// is treated as overdue for display purposes, without mutating the
  /// stored status (so "completed late" history is preserved).
  Homework _withComputedStatus(Homework hw) {
    if (hw.status == HomeworkStatus.completed) return hw;
    if (hw.deadline.isBefore(DateTime.now())) {
      return hw.copyWith(status: HomeworkStatus.overdue);
    }
    return hw;
  }
}

class HomeworkWithSubject {
  final Homework homework;
  final Subject subject;
  const HomeworkWithSubject({required this.homework, required this.subject});
}
