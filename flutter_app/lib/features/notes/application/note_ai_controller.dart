import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/prompts/summarization_prompts.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/locale_providers.dart';

/// The set of one-shot AI actions available on a note (product spec
/// §16): structure, summarize, key points, find dates, find formulas,
/// generate questions. Mirrors `MaterialAiAction` in the Materials
/// feature but kept separate since "structure this note" only makes
/// sense for freeform notes, not PDFs/images.
enum NoteAiAction { structure, summarize, keyPoints, findDates, findFormulas, generateQuestions }

class NoteAiRequest {
  final NoteAiAction action;
  final String content;
  const NoteAiRequest({required this.action, required this.content});

  @override
  bool operator ==(Object other) =>
      other is NoteAiRequest && other.action == action && other.content == content;
  @override
  int get hashCode => Object.hash(action, content);
}

final noteAiResultProvider =
    FutureProvider.autoDispose.family<String, NoteAiRequest>((ref, request) async {
  final aiService = ref.read(aiServiceProvider);
  final locale = ref.read(localeCodeProvider);

  final systemPrompt = switch (request.action) {
    NoteAiAction.structure => SummarizationPrompts.structureNoteSystem(locale),
    NoteAiAction.summarize => SummarizationPrompts.summarizeSystem(locale),
    NoteAiAction.keyPoints => SummarizationPrompts.keyPointsSystem(locale),
    NoteAiAction.findDates => SummarizationPrompts.findDatesSystem(locale),
    NoteAiAction.findFormulas => SummarizationPrompts.findFormulasSystem(locale),
    NoteAiAction.generateQuestions => SummarizationPrompts.generateQuestionsSystem(locale),
  };

  final response = await aiService.generate(
    systemPrompt: systemPrompt,
    userPrompt: request.content,
  );
  return response.text;
});
