import 'dart:typed_data';

/// Abstraction over the AI backend. The rest of the app (features/*)
/// depends ONLY on this interface, never on `GeminiAIService` directly,
/// so the concrete provider can change without touching UI code.
abstract class AIService {
  /// General-purpose text generation with a system prompt + user content.
  /// [context] carries the minimal relevant context (subject/topic/
  /// homework text/notes excerpt) — never the entire user database.
  Future<AIResponse> generate({
    required String systemPrompt,
    required String userPrompt,
    AIContext? context,
  });

  /// Vision request: recognize homework from a photographed page/board/
  /// notebook. Returns a structured [HomeworkRecognitionResult].
  Future<HomeworkRecognitionResult> recognizeHomeworkImage({
    required Uint8List imageBytes,
    required String mimeType,
    AIContext? context,
  });

  /// Structured test generation. Returns raw JSON text that the caller
  /// parses with `TestGenerationParser` — kept as a string here so this
  /// interface has no dependency on feature-layer models.
  Future<String> generateStructuredJson({
    required String systemPrompt,
    required String userPrompt,
  });
}

/// Minimal, relevant context passed to the AI — deliberately NOT the
/// entire user content graph. See product spec §13 "context-aware AI".
class AIContext {
  final String? subjectName;
  final String? topic;
  final String? homeworkText;
  final String? notesExcerpt;
  final String? materialExcerpt;
  final String localeCode;

  const AIContext({
    this.subjectName,
    this.topic,
    this.homeworkText,
    this.notesExcerpt,
    this.materialExcerpt,
    this.localeCode = 'en',
  });

  String toPromptBlock() {
    final buffer = StringBuffer();
    if (subjectName != null) buffer.writeln('Subject: $subjectName');
    if (topic != null && topic!.isNotEmpty) buffer.writeln('Topic: $topic');
    if (homeworkText != null && homeworkText!.isNotEmpty) {
      buffer.writeln('Homework text: $homeworkText');
    }
    if (notesExcerpt != null && notesExcerpt!.isNotEmpty) {
      buffer.writeln('Relevant notes excerpt: $notesExcerpt');
    }
    if (materialExcerpt != null && materialExcerpt!.isNotEmpty) {
      buffer.writeln('Relevant material excerpt: $materialExcerpt');
    }
    return buffer.toString();
  }
}

class AIResponse {
  final String text;
  final DateTime generatedAt;

  const AIResponse({required this.text, required this.generatedAt});
}

class HomeworkRecognitionResult {
  final String subjectGuessKey;
  final String title;
  final String description;
  final double confidence;

  const HomeworkRecognitionResult({
    required this.subjectGuessKey,
    required this.title,
    required this.description,
    required this.confidence,
  });
}

/// Thrown when [AppConfig.hasValidApiKeyConfigured] is false. UI layers
/// catch this specifically to show the "AI not configured" state instead
/// of a generic error.
class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
  @override
  String toString() => 'Gemini API key is not configured for this build.';
}

/// Thrown on any network/timeout failure reaching Gemini.
class AINetworkException implements Exception {
  final String message;
  const AINetworkException(this.message);
  @override
  String toString() => 'AI network error: $message';
}

/// Thrown when Gemini returns a non-2xx response (invalid key, rate
/// limit, server error, etc.), carrying the HTTP status for UI mapping.
class AIApiException implements Exception {
  final int statusCode;
  final String message;
  const AIApiException(this.statusCode, this.message);
  @override
  String toString() => 'AI API error ($statusCode): $message';
}

/// Thrown when the model's response could not be parsed into the
/// expected structure (e.g. malformed test-generation JSON).
class AIParsingException implements Exception {
  final String message;
  const AIParsingException(this.message);
  @override
  String toString() => 'AI parsing error: $message';
}
