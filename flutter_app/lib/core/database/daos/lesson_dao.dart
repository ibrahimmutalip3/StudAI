import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'lesson_dao.g.dart';

@DriftAccessor(tables: [Lessons, Subjects])
class LessonDao extends DatabaseAccessor<AppDatabase> with _$LessonDaoMixin {
  LessonDao(super.db);

  Stream<List<LessonWithSubject>> watchAll() {
    final query = select(lessons).join([
      innerJoin(subjects, subjects.id.equalsExp(lessons.subjectId)),
    ])
      ..orderBy([
        OrderingTerm.asc(lessons.dayOfWeek),
        OrderingTerm.asc(lessons.startTime),
      ]);

    return query.watch().map((rows) => rows
        .map((row) => LessonWithSubject(
              lesson: row.readTable(lessons),
              subject: row.readTable(subjects),
            ))
        .toList());
  }

  Stream<List<LessonWithSubject>> watchForDay(int dayOfWeek) {
    return watchAll()
        .map((l) => l.where((x) => x.lesson.dayOfWeek == dayOfWeek).toList());
  }

  Future<void> upsert(LessonsCompanion lesson) {
    return into(lessons).insertOnConflictUpdate(lesson);
  }

  Future<void> deleteById(String id) {
    return (delete(lessons)..where((t) => t.id.equals(id))).go();
  }
}

class LessonWithSubject {
  final Lesson lesson;
  final Subject subject;
  const LessonWithSubject({required this.lesson, required this.subject});
}
