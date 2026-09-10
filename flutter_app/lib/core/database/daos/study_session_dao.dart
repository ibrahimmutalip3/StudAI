import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'study_session_dao.g.dart';

@DriftAccessor(tables: [StudySessions, Subjects, Homeworks])
class StudySessionDao extends DatabaseAccessor<AppDatabase>
    with _$StudySessionDaoMixin {
  StudySessionDao(super.db);

  Future<String> startSession(StudySessionsCompanion session) async {
    await into(studySessions).insert(session);
    return session.id.value;
  }

  Future<void> endSession(String id, {required int durationSeconds}) {
    return (update(studySessions)..where((t) => t.id.equals(id))).write(
      StudySessionsCompanion(
        endedAt: Value(DateTime.now()),
        durationSeconds: Value(durationSeconds),
      ),
    );
  }

  Stream<List<StudySession>> watchAll() {
    return (select(studySessions)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<List<StudySession>> getBetween(DateTime start, DateTime end) {
    return (select(studySessions)
          ..where((t) => t.startedAt.isBetweenValues(start, end)))
        .get();
  }

  /// Aggregates total study seconds per subject within a date range, used
  /// by the Statistics screen's "study time by subject" breakdown.
  Future<Map<String, int>> secondsBySubject(DateTime start, DateTime end) async {
    final rows = await getBetween(start, end);
    final result = <String, int>{};
    for (final row in rows) {
      final subjectId = row.subjectId ?? 'other';
      result[subjectId] = (result[subjectId] ?? 0) + row.durationSeconds;
    }
    return result;
  }
}
