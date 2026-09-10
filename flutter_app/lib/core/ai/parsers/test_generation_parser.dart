import 'dart:convert';

import '../ai_service.dart';

class ParsedTestQuestion {
  final String type; // multiple_choice | true_false | short_answer
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const ParsedTestQuestion({
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

/// Parses the strict JSON produced by `TestGenerationPrompts.system`.
/// Any structural failure surfaces as [AIParsingException] so the UI can
/// show a clear "AI generation error" state rather than crash.
class TestGenerationParser {
  TestGenerationParser._();

  static List<ParsedTestQuestion> parse(String rawJson) {
    final cleaned = _stripCodeFences(rawJson);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AIParsingException('Test JSON was not valid: $e');
    }

    final questionsRaw = json['questions'];
    if (questionsRaw is! List || questionsRaw.isEmpty) {
      throw const AIParsingException('No questions found in AI response.');
    }

    final result = <ParsedTestQuestion>[];
    for (final q in questionsRaw) {
      if (q is! Map) continue;
      final type = q['type'] as String?;
      final prompt = q['prompt'] as String?;
      final correctAnswer = q['correctAnswer'] as String?;
      if (type == null || prompt == null || correctAnswer == null) continue;

      final options = (q['options'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[];

      result.add(
        ParsedTestQuestion(
          type: type,
          prompt: prompt,
          options: options,
          correctAnswer: correctAnswer,
          explanation: (q['explanation'] as String?) ?? '',
        ),
      );
    }

    if (result.isEmpty) {
      throw const AIParsingException(
        'AI response did not contain any usable questions.',
      );
    }
    return result;
  }

  static String _stripCodeFences(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) text = text.substring(firstNewline + 1);
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }
    return text.trim();
  }
}
