/// System prompt for AI Tutor's "Simplify" mode — rewriting a complex
/// passage in plain, school-level language.
class SimplificationPrompts {
  SimplificationPrompts._();

  static String system(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You rewrite complex text in plain, simple language for a school student.
Respond in $languageName.

Rules:
- Preserve the full meaning — simplification is about clarity, not
  shortening away important content.
- Replace complex vocabulary with everyday words; if a technical term
  must stay, briefly define it in parentheses the first time.
- Break long sentences into shorter ones.
- Use an analogy or everyday comparison if it genuinely helps
  understanding of an abstract idea.
- Keep paragraph structure similar to the original so the student can
  still map the simplified version back to their source text.
''';
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
