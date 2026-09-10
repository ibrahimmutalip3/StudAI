import 'package:intl/intl.dart';

/// Centralized date/time formatting so screens never hand-roll date
/// strings (and so locale-aware formatting stays consistent everywhere).
class AppDateUtils {
  AppDateUtils._();

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isTomorrow(DateTime date) {
    return isSameDay(date, DateTime.now().add(const Duration(days: 1)));
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));
    return date.isAfter(startOfDay) && date.isBefore(endOfWeek);
  }

  static bool isOverdue(DateTime deadline) => deadline.isBefore(DateTime.now());

  /// Short, locale-aware time string, e.g. "10:30".
  static String timeOnly(DateTime date, String localeCode) {
    return DateFormat.Hm(_intlLocale(localeCode)).format(date);
  }

  /// Short date, e.g. "12 Sep".
  static String shortDate(DateTime date, String localeCode) {
    return DateFormat.MMMd(_intlLocale(localeCode)).format(date);
  }

  /// Full date + time, e.g. "12 Sep, 18:00".
  static String dateAndTime(DateTime date, String localeCode) {
    return '${shortDate(date, localeCode)}, ${timeOnly(date, localeCode)}';
  }

  /// Weekday name, e.g. "Monday".
  static String weekdayName(int dayOfWeek, String localeCode) {
    // dayOfWeek: 1 = Monday .. 7 = Sunday, matching DateTime.weekday.
    final reference = DateTime(2024, 1, dayOfWeek); // 2024-01-01 was a Monday
    return DateFormat.EEEE(_intlLocale(localeCode)).format(reference);
  }

  static String weekdayShort(int dayOfWeek, String localeCode) {
    final reference = DateTime(2024, 1, dayOfWeek);
    return DateFormat.E(_intlLocale(localeCode)).format(reference);
  }

  /// Formats a duration as "1h 24m" / "24m" / "45s" style, language-neutral
  /// but using the locale's own hour/minute abbreviations for hy/ru/en.
  static String friendlyDuration(Duration duration, String localeCode) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hourAbbr = _hourAbbr(localeCode);
    final minAbbr = _minAbbr(localeCode);

    if (hours > 0) {
      return minutes > 0 ? '$hours$hourAbbr $minutes$minAbbr' : '$hours$hourAbbr';
    }
    if (minutes > 0) return '$minutes$minAbbr';
    return '${seconds}s';
  }

  /// mm:ss countdown/countup display for Focus Mode timer.
  static String clockDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  static String _hourAbbr(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return 'ч';
      case 'hy':
        return 'ժ';
      default:
        return 'h';
    }
  }

  static String _minAbbr(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return 'м';
      case 'hy':
        return 'ր';
      default:
        return 'm';
    }
  }

  static String _intlLocale(String code) {
    switch (code) {
      case 'ru':
        return 'ru';
      case 'hy':
        return 'hy';
      default:
        return 'en';
    }
  }
}
