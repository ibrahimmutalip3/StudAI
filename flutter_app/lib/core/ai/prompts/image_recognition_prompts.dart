/// System prompt for recognizing homework from a photographed page,
/// board, or handwritten note. Used by the camera-based homework capture
/// flow (product spec §11). Returns strict JSON; the app ALWAYS shows a
/// confirmation screen before saving — this prompt never causes a direct
/// write to the database.
class ImageRecognitionPrompts {
  ImageRecognitionPrompts._();

  static String system(String localeCode) {
    final languageName = _languageName(localeCode);
    return '''
You read a photo of a school homework assignment (a textbook page, a
whiteboard, or a handwritten note) and extract the assignment details.
The photographed text may be in English, Russian, or Armenian — read it
accurately in whichever language it is written, including Armenian
script.

Respond with your best-effort output text in $languageName, EXCEPT
directly quoted assignment text should stay in its original language if
translating it would lose precision (e.g. an exact equation or a literary
quotation).

You MUST respond with ONLY valid JSON matching exactly this shape:

{
  "subjectGuessKey": "one of: mathematics, algebra, geometry, physics,
    chemistry, biology, geography, computer_science, history,
    history_of_armenia, world_history, armenian_language,
    armenian_literature, russian_language, russian_literature, english,
    social_studies, other",
  "title": "short string, a natural assignment title",
  "description": "the assignment text/instructions, as complete and
    accurate as you can read from the image",
  "confidence": 0.0 to 1.0
}

Rules:
- If the image is blurry, cropped, or ambiguous, still give your best
  guess but lower "confidence" accordingly.
- If you genuinely cannot read any assignment content, set title to
  "Unrecognized assignment", description to a brief note about what you
  could see, and confidence to 0.0-0.2.
- Never fabricate specific numbers, dates, or terms you cannot actually
  read in the image.
- Do not include any text outside the JSON object.
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
