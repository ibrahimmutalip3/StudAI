import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'test_dao.g.dart';

@DriftAccessor(tables: [Tests, TestQuestions, Subjects])
class TestDao extends DatabaseAccessor<AppDatabase> with _$TestDaoMixin {
  TestDao(super.db);

  Stream<List<TestWithSubject>> watchAll() {
    final query = select(tests).join([
      innerJoin(subjects, subjects.id.equalsExp(tests.subjectId)),
    ])
      ..orderBy([OrderingTerm.desc(tests.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => TestWithSubject(
              test: row.readTable(tests),
              subject: row.readTable(subjects),
            ))
        .toList());
  }

  Future<Test?> getById(String id) {
    return (select(tests)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<TestQuestion>> watchQuestions(String testId) {
    return (select(testQuestions)
          ..where((t) => t.testId.equals(testId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  Future<void> upsertTest(TestsCompanion test) {
    return into(tests).insertOnConflictUpdate(test);
  }

  Future<void> upsertQuestion(TestQuestionsCompanion question) {
    return into(testQuestions).insertOnConflictUpdate(question);
  }

  Future<void> recordAnswer(String questionId, String answer) {
    return (update(testQuestions)..where((t) => t.id.equals(questionId)))
        .write(TestQuestionsCompanion(userAnswer: Value(answer)));
  }

  Future<void> recordScore(String testId, int correct, int total) {
    return (update(tests)..where((t) => t.id.equals(testId))).write(
      TestsCompanion(
        lastScoreCorrect: Value(correct),
        lastScoreTotal: Value(total),
        lastTakenAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> resetAnswers(String testId) async {
    final questions = await (select(testQuestions)
          ..where((t) => t.testId.equals(testId)))
        .get();
    for (final q in questions) {
      await (update(testQuestions)..where((t) => t.id.equals(q.id)))
          .write(const TestQuestionsCompanion(userAnswer: Value(null)));
    }
  }

  Future<void> deleteById(String id) async {
    await (delete(testQuestions)..where((t) => t.testId.equals(id))).go();
    await (delete(tests)..where((t) => t.id.equals(id))).go();
  }
}

class TestWithSubject {
  final Test test;
  final Subject subject;
  const TestWithSubject({required this.test, required this.subject});
}
