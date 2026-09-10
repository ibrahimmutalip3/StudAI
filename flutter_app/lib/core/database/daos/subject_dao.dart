import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subject_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectDao extends DatabaseAccessor<AppDatabase> with _$SubjectDaoMixin {
  SubjectDao(super.db);

  Stream<List<Subject>> watchAll() {
    return (select(subjects)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Subject?> getById(String id) {
    return (select(subjects)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(SubjectsCompanion subject) {
    return into(subjects).insertOnConflictUpdate(subject);
  }

  Future<void> deleteCustom(String id) {
    return (delete(subjects)
          ..where((t) => t.id.equals(id) & t.isCustom.equals(true)))
        .go();
  }
}
