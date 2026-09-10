import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/ai/prompts/summarization_prompts.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/locale_providers.dart';

/// The set of one-shot AI actions available on a study material or note
/// (product spec §15/§16): summarize, key points, find dates, find
/// formulas, generate review questions. Each is a stateless request —
/// results are shown inline and can be saved via the AI Tutor's "Saved
/// AI Responses" flow from the caller screen.
enum MaterialAiAction { summarize, keyPoints, findDates, findFormulas, generateQuestions }

class MaterialAiRequest {
  final MaterialAiAction action;
  final String content;
  const MaterialAiRequest({required this.action, required this.content});

  @override
  bool operator ==(Object other) =>
      other is MaterialAiRequest && other.action == action && other.content == content;
  @override
  int get hashCode => Object.hash(action, content);
}

final materialAiResultProvider =
    FutureProvider.autoDispose.family<String, MaterialAiRequest>((ref, request) async {
  final aiService = ref.read(aiServiceProvider);
  final locale = ref.read(localeCodeProvider);

  final systemPrompt = switch (request.action) {
    MaterialAiAction.summarize => SummarizationPrompts.summarizeSystem(locale),
    MaterialAiAction.keyPoints => SummarizationPrompts.keyPointsSystem(locale),
    MaterialAiAction.findDates => SummarizationPrompts.findDatesSystem(locale),
    MaterialAiAction.findFormulas => SummarizationPrompts.findFormulasSystem(locale),
    MaterialAiAction.generateQuestions => SummarizationPrompts.generateQuestionsSystem(locale),
  };

  final response = await aiService.generate(
    systemPrompt: systemPrompt,
    userPrompt: request.content,
  );
  return response.text;
});
