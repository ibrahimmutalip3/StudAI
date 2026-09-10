import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dao_providers.dart';

/// Live app locale, derived from persisted [UserSettingsTable.localeCode].
/// Defaults to the device locale on first run (handled in onboarding),
/// falling back to English if unset or unsupported.
final localeProvider = StreamProvider<Locale>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return dao.watch().map((s) {
    switch (s.localeCode) {
      case 'ru':
        return const Locale('ru');
      case 'hy':
        return const Locale('hy');
      default:
        return const Locale('en');
    }
  });
});

/// Convenience: current locale code as a plain string ('en' | 'ru' | 'hy'),
/// used throughout the AI layer and formatting utilities that don't want
/// a full BuildContext dependency.
final localeCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider).valueOrNull;
  return locale?.languageCode ?? 'en';
});

final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return dao.watch().map((s) {
    switch (s.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  });
});
