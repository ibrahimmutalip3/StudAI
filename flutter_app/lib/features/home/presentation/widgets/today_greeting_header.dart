import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// The Today screen's opening moment — a Lora display greeting that
/// reflects time of day, plus the student's name when set. This is one
/// of the two screens (with onboarding) that gets the warmer display
/// typeface, per DESIGN.md.
class TodayGreetingHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;

  const TodayGreetingHeader({
    super.key,
    required this.displayName,
    required this.onSearchTap,
    required this.onProfileTap,
  });

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greeting = _greeting(l10n);
    final title = displayName.trim().isEmpty
        ? greeting
        : l10n.hiName(displayName.trim());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.trim().isEmpty ? greeting : greeting,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: textTheme.displayMedium,
              ),
            ],
          ),
        ),
        _RoundIconButton(icon: PhosphorIconsRegular.magnifyingGlass, onTap: onSearchTap),
        const SizedBox(width: AppSpacing.sm),
        _RoundIconButton(icon: PhosphorIconsRegular.userCircle, onTap: onProfileTap),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppTouchTarget.min,
          height: AppTouchTarget.min,
          child: Icon(icon, size: AppIconSize.md, color: scheme.onSurface),
        ),
      ),
    );
  }
}
