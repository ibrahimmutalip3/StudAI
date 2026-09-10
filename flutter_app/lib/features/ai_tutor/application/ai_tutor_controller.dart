import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/ai/ai_error_translator.dart';
import '../../../core/ai/prompts/explanation_prompts.dart';
import '../../../core/ai/prompts/solving_prompts.dart';
import '../../../core/ai/prompts/checking_prompts.dart';
import '../../../core/ai/prompts/simplification_prompts.dart';
import '../../../core/ai/prompts/test_generation_prompts.dart';
import '../../../core/ai/parsers/test_generation_parser.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dao_providers.dart';
import '../../../core/providers/locale_providers.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/ai_tutor_launch_args.dart';

class AiTutorState {
  final AiMode mode;
  final String? subjectKey;
  final String? subjectName;
  final String? topic;
  final String? homeworkText;
  final String? notesExcerpt;
  final String? materialExcerpt;
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final bool errorIsRetryable;

  const AiTutorState({
    this.mode = AiMode.explain,
    this.subjectKey,
    this.subjectName,
    this.topic,
    this.homeworkText,
    this.notesExcerpt,
    this.materialExcerpt,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.errorIsRetryable = true,
  });

  AiTutorState copyWith({
    AiMode? mode,
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    bool? errorIsRetryable,
  }) {
    return AiTutorState(
      mode: mode ?? this.mode,
      subjectKey: subjectKey,
      subjectName: subjectName,
      topic: topic,
      homeworkText: homeworkText,
      notesExcerpt: notesExcerpt,
      materialExcerpt: materialExcerpt,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorIsRetryable: errorIsRetryable ?? this.errorIsRetryable,
    );
  }
}

class AiTutorController extends StateNotifier<AiTutorState> {
  final AIService _aiService;
  final String Function() _localeCode;

  AiTutorController(this._aiService, this._localeCode, AiTutorLaunchArgs? args)
      : super(AiTutorState(
          mode: args?.mode ?? AiMode.explain,
          subjectKey: args?.subjectKey,
          subjectName: args?.subjectName,
          topic: args?.topic,
          homeworkText: args?.homeworkText,
          notesExcerpt: args?.notesExcerpt,
          materialExcerpt: args?.materialExcerpt,
        ));

  void setMode(AiMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  AIContext _buildContext() {
    return AIContext(
      subjectName: state.subjectName,
      topic: state.topic,
      homeworkText: state.homeworkText,
      notesExcerpt: state.notesExcerpt,
      materialExcerpt: state.materialExcerpt,
      localeCode: _localeCode(),
    );
  }

  String _systemPromptForMode(AiMode mode) {
    final locale = _localeCode();
    switch (mode) {
      case AiMode.explain:
        return ExplanationPrompts.system(locale);
      case AiMode.solveTogether:
        return SolvingPrompts.solveTogetherSystem(locale);
      case AiMode.solution:
        return SolvingPrompts.fullSolutionSystem(locale);
      case AiMode.checkAnswer:
        return CheckingPrompts.system(locale);
      case AiMode.simplify:
        return SimplificationPrompts.system(locale);
      case AiMode.generateTest:
        return TestGenerationPrompts.system(locale);
      case AiMode.imageRecognition:
        return ExplanationPrompts.system(locale);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final userMessage = ChatMessage(role: ChatRole.user, content: text.trim(), timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    try {
      final response = await _aiService.generate(
        systemPrompt: _systemPromptForMode(state.mode),
        userPrompt: text.trim(),
        context: state.messages.length <= 1 ? _buildContext() : null,
      );
      final assistantMessage = ChatMessage(
        role: ChatRole.assistant,
        content: response.text,
        timestamp: response.generatedAt,
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      final presentation = AiErrorTranslator.translate(e, localeCode: _localeCode());
      state = state.copyWith(
        isSending: false,
        errorMessage: presentation.message,
        errorIsRetryable: presentation.isRetryable,
      );
    }
  }

  void retryLast() {
    final lastUser = state.messages.reversed.firstWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => ChatMessage(role: ChatRole.user, content: '', timestamp: DateTime.now()),
    );
    if (lastUser.content.isEmpty) return;
    state = state.copyWith(
      messages: state.messages.sublist(0, state.messages.length - 1),
      clearError: true,
    );
    sendMessage(lastUser.content);
  }

  void clearConversation() {
    state = state.copyWith(messages: [], clearError: true);
  }
}

final aiTutorControllerProvider =
    StateNotifierProvider.autoDispose.family<AiTutorController, AiTutorState, AiTutorLaunchArgs?>(
  (ref, args) {
    return AiTutorController(
      ref.watch(aiServiceProvider),
      () => ref.read(localeCodeProvider),
      args,
    );
  },
);

/// Request payload for the "Generate Test" mode's structured flow, which
/// produces a saved Test/TestQuestion set rather than a chat reply. Kept
/// apart from [AiTutorController] so the chat UI and the structured
/// generation UI don't have to share one state shape.
class TestGenerationRequest {
  final String subjectId;
  final String subjectName;
  final String topic;
  final String difficulty;
  final int questionCount;
  final List<String> questionTypes;

  const TestGenerationRequest({
    required this.subjectId,
    required this.subjectName,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.questionTypes,
  });
}

final testGenerationProvider = FutureProvider.autoDispose.family<String, TestGenerationRequest>(
  (ref, request) async {
    final aiService = ref.read(aiServiceProvider);
    final locale = ref.read(localeCodeProvider);

    final rawJson = await aiService.generateStructuredJson(
      systemPrompt: TestGenerationPrompts.system(locale),
      userPrompt: TestGenerationPrompts.userPrompt(
        subject: request.subjectName,
        topic: request.topic,
        difficulty: request.difficulty,
        questionCount: request.questionCount,
        questionTypes: request.questionTypes,
      ),
    );

    final parsed = TestGenerationParser.parse(rawJson);
    final testDao = ref.read(testDaoProvider);
    final testId = IdGenerator.next();

    await testDao.upsertTest(
      TestsCompanion(
        id: Value(testId),
        title: Value(request.topic.isNotEmpty ? request.topic : request.subjectName),
        subjectId: Value(request.subjectId),
        topic: Value(request.topic),
        difficulty: Value(request.difficulty),
      ),
    );

    for (var i = 0; i < parsed.length; i++) {
      final q = parsed[i];
      await testDao.upsertQuestion(
        TestQuestionsCompanion(
          id: Value(IdGenerator.next()),
          testId: Value(testId),
          type: Value(_questionTypeFrom(q.type)),
          prompt: Value(q.prompt),
          optionsJson: Value(jsonEncode(q.options)),
          correctAnswer: Value(q.correctAnswer),
          explanation: Value(q.explanation),
          orderIndex: Value(i),
        ),
      );
    }

    return testId;
  },
);

TestQuestionType _questionTypeFrom(String raw) {
  switch (raw) {
    case 'true_false':
      return TestQuestionType.trueFalse;
    case 'short_answer':
      return TestQuestionType.shortAnswer;
    default:
      return TestQuestionType.multipleChoice;
  }
}
