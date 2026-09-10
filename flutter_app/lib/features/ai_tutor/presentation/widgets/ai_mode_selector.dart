import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/tables.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Horizontal scrolling row of AI Tutor mode chips. Kept separate from
/// the mode bottom sheet (see [AiModeSheet]) so it can sit compactly in
/// the app bar area while the sheet gives each mode room to explain
/// itself with a description line.
class AiModeSelector extends StatelessWidget {
  final AiMode selected;
  final ValueChanged<AiMode> onChanged;
  const AiModeSelector({super.key, required this.selected, required this.onChanged});

  static const _modes = [
    AiMode.explain,
    AiMode.solveTogether,
    AiMode.solution,
    AiMode.checkAnswer,
    AiMode.simplify,
    AiMode.generateTest,
  ];

  IconData _iconFor(AiMode mode) {
    switch (mode) {
      case AiMode.explain:
        return PhosphorIconsRegular.lightbulb;
      case AiMode.solveTogether:
        return PhosphorIconsRegular.handshake;
      case AiMode.solution:
        return PhosphorIconsRegular.checkCircle;
      case AiMode.checkAnswer:
        return PhosphorIconsRegular.magnifyingGlass;
      case AiMode.simplify:
        return PhosphorIconsRegular.textAa;
      case AiMode.generateTest:
        return PhosphorIconsRegular.testTube;
      case AiMode.imageRecognition:
        return PhosphorIconsRegular.camera;
    }
  }

  String _labelFor(AppLocalizations l10n, AiMode mode) {
    switch (mode) {
      case AiMode.explain:
        return l10n.modeExplain;
      case AiMode.solveTogether:
        return l10n.modeSolveTogether;
      case AiMode.solution:
        return l10n.modeSolution;
      case AiMode.checkAnswer:
        return l10n.modeCheckAnswer;
      case AiMode.simplify:
        return l10n.modeSimplify;
      case AiMode.generateTest:
        return l10n.modeGenerateTest;
      case AiMode.imageRecognition:
        return l10n.modeExplain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final mode = _modes[index];
          final isSelected = mode == selected;
          return Material(
            color: isSelected ? scheme.primary : scheme.surfaceContainerHigh,
            borderRadius: AppRadii.pillRadius,
            child: InkWell(
              onTap: () => onChanged(mode),
              borderRadius: AppRadii.pillRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconFor(mode),
                      size: AppIconSize.sm,
                      color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _labelFor(l10n, mode),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-detail mode picker sheet, shown from the empty state / a "change
/// mode" affordance, with a description line for each mode.
class AiModeSheet extends StatelessWidget {
  final AiMode selected;
  final ValueChanged<AiMode> onSelected;
  const AiModeSheet({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selector = AiModeSelector(selected: selected, onChanged: (_) {});

    final items = <(AiMode, IconData, String, String)>[
      (AiMode.explain, PhosphorIconsRegular.lightbulb, l10n.modeExplain, l10n.modeExplainDesc),
      (AiMode.solveTogether, PhosphorIconsRegular.handshake, l10n.modeSolveTogether, l10n.modeSolveTogetherDesc),
      (AiMode.solution, PhosphorIconsRegular.checkCircle, l10n.modeSolution, l10n.modeSolutionDesc),
      (AiMode.checkAnswer, PhosphorIconsRegular.magnifyingGlass, l10n.modeCheckAnswer, l10n.modeCheckAnswerDesc),
      (AiMode.simplify, PhosphorIconsRegular.textAa, l10n.modeSimplify, l10n.modeSimplifyDesc),
      (AiMode.generateTest, PhosphorIconsRegular.testTube, l10n.modeGenerateTest, l10n.modeGenerateTestDesc),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiChooseMode, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            ...items.map((item) => _ModeRow(
                  icon: item.$2,
                  title: item.$3,
                  description: item.$4,
                  selected: item.$1 == selected,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(item.$1);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModeRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: AppRadii.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.surfaceContainerHigh,
                  borderRadius: AppRadii.smRadius,
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.md,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    Text(description, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
