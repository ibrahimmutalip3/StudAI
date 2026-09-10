import 'package:flutter/material.dart';

/// Color system.
///
/// Design decision (see DESIGN.md): the obvious choice for an "AI study
/// app" is a saturated purple gradient. We deliberately steer away from
/// that. The seed is a desaturated indigo-slate — closer to a focused
/// study-lamp blue than a sci-fi AI purple — paired with a warm amber
/// for positive/completion states (never framed as a reward currency,
/// just a warm accent for "done").
///
/// Dark theme is the primary experience (students study at night), built
/// as layered near-black surfaces, never pure #000. Light theme uses soft
/// warm-gray layered surfaces, never pure #FFF.
class AppColors {
  AppColors._();

  // Brand seed — desaturated indigo, not saturated "AI purple".
  static const Color seed = Color(0xFF5B6EE8);

  // Secondary accent — warm amber, used sparingly for positive/complete
  // states and streak-free "you're caught up" moments.
  static const Color amber = Color(0xFFE8A94A);

  // Semantic status colors (tuned, not raw Material red/green).
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFE8A94A);
  static const Color danger = Color(0xFFE0637A);
  static const Color info = Color(0xFF5B9EE8);

  // Subject accent colors — used as small identity tags on subject
  // chips/cards, never as full-screen backgrounds.
  static const Color subjectMath = Color(0xFF5B6EE8);
  static const Color subjectScience = Color(0xFF4CAF7D);
  static const Color subjectHistory = Color(0xFFC77B4C);
  static const Color subjectLanguage = Color(0xFFB05FC2);
  static const Color subjectLiterature = Color(0xFFE0637A);
  static const Color subjectSocial = Color(0xFF5B9EE8);
  static const Color subjectOther = Color(0xFF8A8F98);

  static ColorScheme lightScheme() {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      surface: const Color(0xFFFBFAF8),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF6F4F1),
      surfaceContainer: const Color(0xFFF0EDE9),
      surfaceContainerHigh: const Color(0xFFEAE6E1),
      surfaceContainerHighest: const Color(0xFFE3DFD9),
      onSurface: const Color(0xFF1C1B1F),
      onSurfaceVariant: const Color(0xFF49454F),
      primary: const Color(0xFF4A5BD4),
      secondary: amber,
      error: danger,
      outline: const Color(0xFFD8D2C9),
      outlineVariant: const Color(0xFFE8E3DC),
    );
  }

  static ColorScheme darkScheme() {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      // Near-black, never pure #000. Layered ladder gets *lighter* with
      // elevation, per dark-mode-is-designed-not-inverted doctrine.
      surface: const Color(0xFF131316),
      surfaceContainerLowest: const Color(0xFF0D0D0F),
      surfaceContainerLow: const Color(0xFF19191D),
      surfaceContainer: const Color(0xFF1F1F24),
      surfaceContainerHigh: const Color(0xFF29292F),
      surfaceContainerHighest: const Color(0xFF34343B),
      onSurface: const Color(0xFFECEAE6),
      onSurfaceVariant: const Color(0xFFC9C5D0),
      primary: const Color(0xFF9CA8F5),
      secondary: const Color(0xFFEDC080),
      error: const Color(0xFFEB8B9E),
      outline: const Color(0xFF444249),
      outlineVariant: const Color(0xFF322F36),
    );
  }

  /// Deterministic accent color per subject name, used on chips and
  /// small subject tags. Falls back to [subjectOther].
  static Color forSubjectKey(String subjectKey) {
    switch (subjectKey) {
      case 'mathematics':
      case 'algebra':
      case 'geometry':
      case 'computer_science':
        return subjectMath;
      case 'physics':
      case 'chemistry':
      case 'biology':
      case 'geography':
        return subjectScience;
      case 'history':
      case 'history_of_armenia':
      case 'world_history':
        return subjectHistory;
      case 'armenian_language':
      case 'russian_language':
      case 'english':
        return subjectLanguage;
      case 'armenian_literature':
      case 'russian_literature':
        return subjectLiterature;
      case 'social_studies':
        return subjectSocial;
      default:
        return subjectOther;
    }
  }
}
