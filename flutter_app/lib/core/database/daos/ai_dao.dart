import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'ai_dao.g.dart';

@DriftAccessor(tables: [AiConversations, SavedAiResponses, Subjects])
class AiDao extends DatabaseAccessor<AppDatabase> with _$AiDaoMixin {
  AiDao(super.db);

  Stream<List<AiConversation>> watchConversations() {
    return (select(aiConversations)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<AiConversation?> getConversation(String id) {
    return (select(aiConversations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertConversation(AiConversationsCompanion conversation) {
    return into(aiConversations).insertOnConflictUpdate(conversation);
  }

  Future<void> deleteConversation(String id) {
    return (delete(aiConversations)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<SavedAiResponse>> watchSavedResponses() {
    return (select(savedAiResponses)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch();
  }

  Future<void> saveResponse(SavedAiResponsesCompanion response) {
    return into(savedAiResponses).insertOnConflictUpdate(response);
  }

  Future<void> deleteSavedResponse(String id) {
    return (delete(savedAiResponses)..where((t) => t.id.equals(id))).go();
  }

  Future<List<SavedAiResponse>> search(String query) {
    final like = '%$query%';
    return (select(savedAiResponses)
          ..where((t) => t.title.like(like) | t.content.like(like)))
        .get();
  }
}
