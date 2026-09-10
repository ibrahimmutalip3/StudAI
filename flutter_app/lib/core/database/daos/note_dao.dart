import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Stream<List<Note>> watchAll() {
    return (select(notes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Note>> watchBySubject(String subjectId) {
    return (select(notes)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<Note?> getById(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(NotesCompanion note) {
    return into(notes).insertOnConflictUpdate(note);
  }

  Future<void> delete(String id) {
    return (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Note>> search(String query) {
    final like = '%$query%';
    return (select(notes)
          ..where((t) => t.title.like(like) | t.content.like(like)))
        .get();
  }
}
