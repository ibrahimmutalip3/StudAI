import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system.
///
/// Two families: Inter (UI, body, labels — excellent multi-script support
/// including Armenian and Cyrillic) and Lora (display headings only, for
/// warmth on Today/onboarding — also has full Cyrillic; Armenian falls
/// back gracefully to Inter via TextStyle fallback since Lora's Armenian
/// coverage is partial).
///
/// Both are bundled through google_fonts' asset packaging at build time
/// (not fetched at runtime in production) once `flutter pub get` resolves
/// the font assets — see pubspec.yaml comment.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();
    final display = GoogleFonts.loraTextTheme();

    return base
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(
            fontSize: 40,
            height: 1.15,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          displayMedium: display.displayMedium?.copyWith(
            fontSize: 32,
            height: 1.18,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 28,
            height: 1.2,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 24,
            height: 1.22,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: scheme.onSurface,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: scheme.onSurface,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: scheme.onSurfaceVariant,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: scheme.onSurfaceVariant,
          ),
        )
        .apply(displayColor: scheme.onSurface, bodyColor: scheme.onSurface);
  }
}
