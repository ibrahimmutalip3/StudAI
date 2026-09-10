import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'material_dao.g.dart';

@DriftAccessor(tables: [StudyMaterials, Subjects])
class MaterialDao extends DatabaseAccessor<AppDatabase>
    with _$MaterialDaoMixin {
  MaterialDao(super.db);

  Stream<List<MaterialWithSubject>> watchAll() {
    final query = select(studyMaterials).join([
      innerJoin(subjects, subjects.id.equalsExp(studyMaterials.subjectId)),
    ])
      ..orderBy([OrderingTerm.desc(studyMaterials.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => MaterialWithSubject(
              material: row.readTable(studyMaterials),
              subject: row.readTable(subjects),
            ))
        .toList());
  }

  Stream<List<MaterialWithSubject>> watchBySubject(String subjectId) {
    return watchAll()
        .map((l) => l.where((m) => m.subject.id == subjectId).toList());
  }

  Future<StudyMaterial?> getById(String id) {
    return (select(studyMaterials)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(StudyMaterialsCompanion material) {
    return into(studyMaterials).insertOnConflictUpdate(material);
  }

  Future<void> delete(String id) {
    return (delete(studyMaterials)..where((t) => t.id.equals(id))).go();
  }

  Future<List<StudyMaterial>> search(String query) {
    final like = '%$query%';
    return (select(studyMaterials)
          ..where((t) => t.title.like(like) | t.textContent.like(like)))
        .get();
  }
}

class MaterialWithSubject {
  final StudyMaterial material;
  final Subject subject;
  const MaterialWithSubject({required this.material, required this.subject});
}
