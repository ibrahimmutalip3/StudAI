import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../application/onboarding_controller.dart';
import '../../domain/onboarding_step.dart';
import '../widgets/onboarding_splash.dart';

/// Full onboarding flow: an animated splash (product spec §32 — logo
/// assembles, scales, then morphs into the UI) followed by a short setup
/// wizard (language → name → grade). No "3 seconds then Home" pattern;
/// the splash advances itself and the wizard is skippable at every step.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.screen,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (state.step) {
            OnboardingStep.splash => OnboardingSplash(
                key: const ValueKey('splash'),
                onFinished: controller.advanceFromSplash,
              ),
            OnboardingStep.language => _LanguageStep(
                key: const ValueKey('language'),
                onSelect: controller.selectLanguage,
              ),
            OnboardingStep.name => _NameStep(
                key: const ValueKey('name'),
                controller: _nameController,
                onBack: () => controller.goBackTo(OnboardingStep.language),
                onContinue: (name) => controller.setName(name),
              ),
            OnboardingStep.grade => _GradeStep(
                key: const ValueKey('grade'),
                controller: _gradeController,
                onBack: () => controller.goBackTo(OnboardingStep.name),
                onFinish: (grade) => controller.completeOnboarding(grade),
              ),
          },
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _LanguageStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.onboardingLanguageTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.onboardingLanguageBody, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxl),
          _LanguageOption(label: 'English', code: 'en', onTap: onSelect),
          const SizedBox(height: AppSpacing.md),
          _LanguageOption(label: 'Русский', code: 'ru', onTap: onSelect),
          const SizedBox(height: AppSpacing.md),
          _LanguageOption(label: 'Հայերեն', code: 'hy', onTap: onSelect),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final ValueChanged<String> onTap;
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        borderRadius: AppRadii.lgRadius,
        onTap: () => onTap(code),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
              Icon(PhosphorIconsRegular.caretRight, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;
  const _NameStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
          ),
          const Spacer(),
          Text(l10n.onboardingNameTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.onboardingNameBody, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l10n.onboardingNameHint),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) onContinue(value.trim());
            },
          ),
          const Spacer(flex: 2),
          FilledButton(
            onPressed: controller.text.trim().isEmpty
                ? null
                : () => onContinue(controller.text.trim()),
            child: Text(l10n.onboardingContinue),
          ),
          TextButton(
            onPressed: () => onContinue(''),
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ),
    );
  }
}

class _GradeStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onFinish;
  const _GradeStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
          ),
          const Spacer(),
          Text(l10n.onboardingGradeTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.onboardingGradeBody, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.onboardingGradeHint),
            onSubmitted: onFinish,
          ),
          const Spacer(flex: 2),
          FilledButton(
            onPressed: () => onFinish(controller.text.trim()),
            child: Text(l10n.onboardingGetStarted),
          ),
          TextButton(
            onPressed: () => onFinish(''),
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ),
    );
  }
}
