import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/providers/dao_providers.dart';
import '../domain/onboarding_step.dart';

class OnboardingState {
  final OnboardingStep step;
  final String localeCode;
  final String displayName;
  final String gradeLevel;

  const OnboardingState({
    this.step = OnboardingStep.splash,
    this.localeCode = 'en',
    this.displayName = '',
    this.gradeLevel = '',
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? localeCode,
    String? displayName,
    String? gradeLevel,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      localeCode: localeCode ?? this.localeCode,
      displayName: displayName ?? this.displayName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  final SettingsDao _settingsDao;

  OnboardingController(this._settingsDao) : super(const OnboardingState());

  void advanceFromSplash() {
    state = state.copyWith(step: OnboardingStep.language);
  }

  void selectLanguage(String code) {
    state = state.copyWith(localeCode: code, step: OnboardingStep.name);
  }

  void setName(String name) {
    state = state.copyWith(displayName: name, step: OnboardingStep.grade);
  }

  void goBackTo(OnboardingStep step) {
    state = state.copyWith(step: step);
  }

  Future<void> completeOnboarding(String gradeLevel) async {
    await _settingsDao.updateSettings(
      UserSettingsTableCompanion(
        localeCode: Value(state.localeCode),
        displayName: Value(state.displayName),
        gradeLevel: Value(gradeLevel),
        hasCompletedOnboarding: const Value(true),
      ),
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref.watch(settingsDaoProvider));
});
