import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<UserSettingsTableData> watch() {
    return (select(userSettingsTable)..where((t) => t.id.equals(0)))
        .watchSingle();
  }

  Future<UserSettingsTableData> get() {
    return (select(userSettingsTable)..where((t) => t.id.equals(0)))
        .getSingle();
  }

  Future<void> updateSettings(UserSettingsTableCompanion settings) {
    return (update(userSettingsTable)..where((t) => t.id.equals(0)))
        .write(settings);
  }
}
