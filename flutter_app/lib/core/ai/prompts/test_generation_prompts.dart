/// System prompt for AI Tutor's "Generate Test" mode. Instructs the
/// model to return strict JSON so `TestGenerationParser` can safely
/// parse it into `Test`/`TestQuestion` rows without ambiguity.
class TestGenerationPrompts {
  TestGenerationPrompts._();

  static String system(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You generate school-level test questions. Respond in $languageName for
all question/answer/explanation text.

You MUST respond with ONLY valid JSON matching exactly this shape, with
no markdown code fences, no commentary before or after:

{
  "questions": [
    {
      "type": "multiple_choice" | "true_false" | "short_answer",
      "prompt": "string",
      "options": ["string", "string", "string", "string"],
      "correctAnswer": "string",
      "explanation": "string"
    }
  ]
}

Rules:
- For "multiple_choice": provide exactly 4 plausible options in
  "options", with "correctAnswer" being an exact copy of the correct
  option's text.
- For "true_false": "options" must be exactly ["True", "False"]
  (translated into the target language), "correctAnswer" one of them.
- For "short_answer": "options" must be an empty array []. Keep the
  expected "correctAnswer" concise (a word, phrase, or number) so it can
  be reasonably compared against a free-text answer.
- "explanation" must explain WHY the correct answer is correct, in 1-3
  sentences, usable as feedback after the student answers.
- Match the requested difficulty and question count exactly.
- Do not include any text outside the JSON object. Do not wrap the JSON
  in ```json fences.
''';
  }

  static String userPrompt({
    required String subject,
    required String topic,
    required String difficulty,
    required int questionCount,
    required List<String> questionTypes,
  }) {
    return 'Generate $questionCount questions for subject "$subject", '
        'topic "$topic", difficulty "$difficulty". '
        'Allowed question types: ${questionTypes.join(", ")}.';
  }

  static String _languageName(String code) {
    switch (code) {
      case 'ru':
        return 'Russian';
      case 'hy':
        return 'Armenian';
      default:
        return 'English';
    }
  }
}
