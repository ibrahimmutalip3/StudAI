import 'dart:convert';

import '../ai_service.dart';

class ParsedFlashcard {
  final String front;
  final String back;
  const ParsedFlashcard({required this.front, required this.back});
}

class FlashcardGenerationParser {
  FlashcardGenerationParser._();

  static List<ParsedFlashcard> parse(String rawJson) {
    final cleaned = _stripCodeFences(rawJson);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AIParsingException('Flashcard JSON was not valid: $e');
    }

    final cardsRaw = json['cards'];
    if (cardsRaw is! List || cardsRaw.isEmpty) {
      throw const AIParsingException('No flashcards found in AI response.');
    }

    final result = <ParsedFlashcard>[];
    for (final c in cardsRaw) {
      if (c is! Map) continue;
      final front = c['front'] as String?;
      final back = c['back'] as String?;
      if (front == null || back == null) continue;
      result.add(ParsedFlashcard(front: front, back: back));
    }

    if (result.isEmpty) {
      throw const AIParsingException(
        'AI response did not contain any usable flashcards.',
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
