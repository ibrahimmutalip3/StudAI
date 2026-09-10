import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/parsers/flashcard_generation_parser.dart';
import '../../../core/ai/prompts/flashcard_prompts.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dao_providers.dart';
import '../../../core/providers/locale_providers.dart';
import '../../../core/utils/id_generator.dart';

/// Generates a flashcard deck straight from a subject/topic pair — no
/// source note or material required. Distinct from the "from note" and
/// "from material" flows (which already live inline in their own
/// screens) because there's no existing text content to summarize; the
/// prompt instead asks the model to draw on general subject knowledge.
class FlashcardGenerationController {
  final Ref _ref;
  const FlashcardGenerationController(this._ref);

  Future<String> generateFromTopic({
    required String subjectId,
    required String subjectName,
    required String topic,
  }) async {
    final aiService = _ref.read(aiServiceProvider);
    final locale = _ref.read(localeCodeProvider);

    final rawJson = await aiService.generateStructuredJson(
      systemPrompt: FlashcardPrompts.system(locale),
      userPrompt: FlashcardPrompts.userPrompt(
        sourceContent: 'Subject: $subjectName. Topic: $topic. '
            'Generate flashcards covering the key facts and concepts a '
            'school student would need to know about this topic.',
        cardCount: 10,
      ),
    );
    final cards = FlashcardGenerationParser.parse(rawJson);

    final deckId = IdGenerator.next();
    final dao = _ref.read(flashcardDaoProvider);
    await dao.upsertDeck(
      FlashcardDecksCompanion(
        id: Value(deckId),
        title: Value(topic),
        subjectId: Value(subjectId),
      ),
    );
    for (final card in cards) {
      await dao.upsertCard(
        FlashcardsCompanion(
          id: Value(IdGenerator.next()),
          deckId: Value(deckId),
          front: Value(card.front),
          back: Value(card.back),
          subjectId: Value(subjectId),
        ),
      );
    }
    return deckId;
  }
}

final flashcardGenerationControllerProvider = Provider<FlashcardGenerationController>(
  (ref) => FlashcardGenerationController(ref),
);
