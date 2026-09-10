import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/dao_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/utils/id_generator.dart';

/// Live settings row, watched by the Profile screen and anything else
/// that needs the user's name/grade/locale/theme/notification prefs.
final profileSettingsProvider = StreamProvider<UserSettingsTableData>((ref) {
  return ref.watch(settingsDaoProvider).watch();
});

/// Thin write-side wrapper around [SettingsDao] and [SubjectDao] so the
/// Profile screen's widgets stay declarative and never touch Drift
/// companions directly.
class ProfileController {
  final Ref _ref;
  ProfileController(this._ref);

  Future<void> updateDisplayName(String name) {
    return _ref.read(settingsDaoProvider).update(
          UserSettingsTableCompanion(displayName: Value(name)),
        );
  }

  Future<void> updateGradeLevel(String grade) {
    return _ref.read(settingsDaoProvider).update(
          UserSettingsTableCompanion(gradeLevel: Value(grade)),
        );
  }

  Future<void> updateLocale(String localeCode) {
    return _ref.read(settingsDaoProvider).update(
          UserSettingsTableCompanion(localeCode: Value(localeCode)),
        );
  }

  Future<void> updateThemeMode(String themeMode) {
    return _ref.read(settingsDaoProvider).update(
          UserSettingsTableCompanion(themeMode: Value(themeMode)),
        );
  }

  /// Enables/disables notifications in settings, and — only when turning
  /// them on — requests the OS permission. If the user denies the OS
  /// prompt, the setting is still recorded as "on"; individual schedule
  /// calls will simply have no effect until permission is granted,
  /// mirroring how the OS itself handles this (no separate error state
  /// needed, per product spec §26: nothing to show the user that isn't
  /// already visible in their system notification settings).
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await _ref.read(notificationServiceProvider).requestPermission();
    }
    await _ref.read(settingsDaoProvider).update(
          UserSettingsTableCompanion(notificationsEnabled: Value(enabled)),
        );
  }

  Future<void> addCustomSubject({
    required String name,
    required String colorHex,
  }) async {
    final subjects = await _ref.read(subjectDaoProvider).watchAll().first;
    final nextOrder = subjects.isEmpty
        ? 0
        : subjects.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = IdGenerator.next();
    await _ref.read(subjectDaoProvider).upsert(
          SubjectsCompanion.insert(
            id: id,
            key: id,
            displayNameEn: name,
            displayNameRu: name,
            displayNameHy: name,
            colorHex: colorHex,
            isCustom: const Value(true),
            sortOrder: Value(nextOrder),
          ),
        );
  }

  Future<void> deleteCustomSubject(String id) {
    return _ref.read(subjectDaoProvider).deleteCustom(id);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});
