import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'flashcard_dao.g.dart';

@DriftAccessor(tables: [Flashcards, FlashcardDecks, Subjects])
class FlashcardDao extends DatabaseAccessor<AppDatabase>
    with _$FlashcardDaoMixin {
  FlashcardDao(super.db);

  Stream<List<FlashcardDeck>> watchDecks() {
    return (select(flashcardDecks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Flashcard>> watchCardsInDeck(String deckId) {
    return (select(flashcards)..where((t) => t.deckId.equals(deckId))).watch();
  }

  Future<void> upsertDeck(FlashcardDecksCompanion deck) {
    return into(flashcardDecks).insertOnConflictUpdate(deck);
  }

  Future<void> upsertCard(FlashcardsCompanion card) {
    return into(flashcards).insertOnConflictUpdate(card);
  }

  Future<void> deleteDeck(String id) async {
    await (delete(flashcards)..where((t) => t.deckId.equals(id))).go();
    await (delete(flashcardDecks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteCard(String id) {
    return (delete(flashcards)..where((t) => t.id.equals(id))).go();
  }

  Future<void> recordReview(String cardId, {required bool correct}) async {
    final card =
        await (select(flashcards)..where((t) => t.id.equals(cardId)))
            .getSingleOrNull();
    if (card == null) return;
    await (update(flashcards)..where((t) => t.id.equals(cardId))).write(
      FlashcardsCompanion(
        timesReviewed: Value(card.timesReviewed + 1),
        timesCorrect: Value(card.timesCorrect + (correct ? 1 : 0)),
        lastReviewedAt: Value(DateTime.now()),
      ),
    );
  }
}
