/// System prompt for AI-generated flashcards from notes/materials/topics.
/// Also uses strict JSON so the app can safely create `Flashcard` rows.
class FlashcardPrompts {
  FlashcardPrompts._();

  static String system(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You create flashcards for spaced-repetition style studying. Respond in
$languageName for all card text.

You MUST respond with ONLY valid JSON matching exactly this shape, with
no markdown code fences, no commentary before or after:

{
  "cards": [
    { "front": "string", "back": "string" }
  ]
}

Rules:
- "front" is a short question or prompt (ideally one sentence/phrase).
- "back" is a concise, exact answer — not a paragraph. A good flashcard
  answer is short enough to recall quickly, not re-read like a summary.
- Generate the requested number of cards, covering distinct facts or
  concepts (avoid near-duplicate cards).
- If the source content does not contain enough distinct facts to reach
  the requested count, return fewer cards rather than inventing content
  not supported by the source.
- Do not include any text outside the JSON object.
''';
  }

  static String userPrompt({
    required String sourceContent,
    required int cardCount,
  }) {
    return 'Create up to $cardCount flashcards from this content:\n\n'
        '$sourceContent';
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
