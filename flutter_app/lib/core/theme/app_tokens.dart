import 'package:flutter/widgets.dart';

/// Design tokens — the single source of truth for spacing, radii, motion
/// durations/curves, and icon sizing. No widget file should ever write a
/// raw numeric EdgeInsets, BorderRadius, or Duration; everything routes
/// through here.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: xxl);
}

/// One radius family, applied consistently: soft everywhere (12–20),
/// pill only for interactive chips/pills, per the design contract in
/// DESIGN.md.
class AppRadii {
  AppRadii._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

/// Canonical motion durations & curves. See DESIGN.md §Motion for the
/// rationale (Jakub-primary: production polish, subtle physics).
class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration container = Duration(milliseconds: 340);
  static const Duration screen = Duration(milliseconds: 420);

  // Exits are faster than enters.
  static const Duration exitFast = Duration(milliseconds: 140);
  static const Duration exitStandard = Duration(milliseconds: 180);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve morph = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.easeOutBack;
}

class AppIconSize {
  AppIconSize._();

  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
  static const double xl = 36;
}

/// Minimum interactive target, per accessibility + touch-psychology
/// doctrine (48dp Android / 44pt iOS — we use the larger, safer value).
class AppTouchTarget {
  AppTouchTarget._();
  static const double min = 48;
}
