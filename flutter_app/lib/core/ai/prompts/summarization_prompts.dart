/// System prompts for material/note summarization, key-point extraction,
/// date/formula finding, and question generation (used by Materials and
/// Notes features).
class SummarizationPrompts {
  SummarizationPrompts._();

  static String summarizeSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are helping a student summarize study material. Respond in
$languageName.

Produce a concise summary (roughly 4-8 sentences unless the material is
very short) that:
- Captures the main ideas in the order they matter, not the order they
  appeared.
- Uses plain, exam-relevant language.
- Omits filler and repeated points from the source.
Do not add information that isn't in the source material.
''';
  }

  static String keyPointsSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are extracting key points from study material for a student.
Respond in $languageName.

Return a short bulleted list (5-10 points) of the most important, most
likely-to-be-tested ideas from the material. Each bullet should be a
single clear statement, not a fragment.
''';
  }

  static String findDatesSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are extracting important dates/events from study material (likely
history). Respond in $languageName.

Return a list of "Date — Event" pairs found in or clearly implied by the
material, ordered chronologically. If no dates are present, say so
plainly instead of inventing any.
''';
  }

  static String findFormulasSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are extracting formulas from study material (likely math, physics,
or chemistry). Respond in $languageName.

Return a list of each formula found, with a one-line plain-language
explanation of what it calculates and what each symbol means. If no
formulas are present, say so plainly instead of inventing any.
''';
  }

  static String generateQuestionsSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are generating comprehension/review questions from study material,
for a student to self-test with. Respond in $languageName.

Return 5-8 questions that test understanding of the material (not just
recall of exact wording). Vary question style (some "why"/"how", not
only "what"). Do not include answers — questions only.
''';
  }

  static String structureNoteSystem(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You are helping a student restructure a messy note into a clean,
well-organized version. Respond in $languageName.

Rules:
- Preserve all factual content — do not drop or invent information.
- Organize with clear headings/sections where the content has distinct
  parts.
- Use bullet points for lists of related facts.
- Fix obvious structural issues (e.g. a sentence that's actually two
  separate ideas) without changing the meaning.
- Output should be ready to read as a clean study note, using simple
  Markdown formatting (##, -, **bold** for key terms).
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
