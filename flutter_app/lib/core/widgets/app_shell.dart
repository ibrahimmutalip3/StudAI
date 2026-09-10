import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_tokens.dart';
import '../l10n/generated/app_localizations.dart';

/// The app's primary navigation chrome. Deliberately NOT a stock
/// Material [BottomNavigationBar] or [NavigationBar] — a floating,
/// rounded pill bar that sits above the content with a soft elevation
/// separation, per DESIGN.md's "modern floating/adaptive navigation"
/// direction. The AI Tutor destination (index 2) is visually emphasized
/// as the app's signature entry point.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _destinations = [
    _NavDestination(path: '/today', icon: PhosphorIconsRegular.house, activeIcon: PhosphorIconsFill.house),
    _NavDestination(path: '/homework', icon: PhosphorIconsRegular.checkSquare, activeIcon: PhosphorIconsFill.checkSquare),
    _NavDestination(path: '/ai-tutor', icon: PhosphorIconsRegular.sparkle, activeIcon: PhosphorIconsFill.sparkle, isEmphasized: true),
    _NavDestination(path: '/materials', icon: PhosphorIconsRegular.stack, activeIcon: PhosphorIconsFill.stack),
    _NavDestination(path: '/profile', icon: PhosphorIconsRegular.userCircle, activeIcon: PhosphorIconsFill.userCircle),
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.navToday,
      l10n.navHomework,
      l10n.navAiTutor,
      l10n.navMaterials,
      l10n.navProfile,
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.sm,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.pillRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_destinations.length, (i) {
              final dest = _destinations[i];
              final selected = i == currentIndex;
              return Expanded(
                child: _NavItem(
                  icon: selected ? dest.activeIcon : dest.icon,
                  label: labels[i],
                  selected: selected,
                  emphasized: dest.isEmphasized,
                  onTap: () {
                    if (!selected) context.go(dest.path);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final bool isEmphasized;
  const _NavDestination({
    required this.path,
    required this.icon,
    required this.activeIcon,
    this.isEmphasized = false,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.emphasized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final iconColor = emphasized
        ? (selected ? scheme.onPrimary : scheme.primary)
        : (selected ? scheme.primary : scheme.onSurfaceVariant);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.standard,
              curve: AppMotion.morph,
              padding: EdgeInsets.symmetric(
                horizontal: emphasized && selected ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: emphasized
                    ? scheme.primary
                    : (selected ? scheme.primaryContainer : Colors.transparent),
                borderRadius: AppRadii.pillRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppIconSize.md, color: iconColor),
                  AnimatedSize(
                    duration: AppMotion.standard,
                    curve: AppMotion.morph,
                    child: (selected && (emphasized || true))
                        ? Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: Text(
                              label,
                              style: textTheme.labelSmall?.copyWith(
                                color: emphasized ? scheme.onPrimary : scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
