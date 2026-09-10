import '../database/app_database.dart';

/// Resolves the correct localized display name from a [Subject] row,
/// since Drift stores all three translations as plain columns rather
/// than routing through ARB (subjects are user data, not UI chrome).
extension SubjectLocalization on Subject {
  String displayName(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return displayNameRu;
      case 'hy':
        return displayNameHy;
      default:
        return displayNameEn;
    }
  }
}
