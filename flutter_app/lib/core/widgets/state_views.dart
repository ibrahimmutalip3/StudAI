import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_tokens.dart';

/// A designed empty state with an icon, message, and an optional primary
/// action — never a blank screen (product spec §39).
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppIconSize.xl, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A designed error state — never a raw stack trace (product spec §26).
class ErrorStateView extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorStateView({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EmptyStateView(
      icon: PhosphorIconsRegular.warningCircle,
      title: message,
      actionLabel: actionLabel,
      onAction: onAction,
    ).let((w) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(onSurfaceVariant: scheme.error),
          ),
          child: w,
        ));
  }
}

/// Offline banner + retry, shown wherever a feature needs connectivity
/// (AI screens) but the device has none.
class OfflineStateView extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineStateView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: PhosphorIconsRegular.wifiSlash,
      title: 'No internet connection',
      subtitle: 'AI features need a connection. Everything else still works offline.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

/// Skeleton loader matching a card-list layout, shown instead of a bare
/// spinner on content screens (per anti-patterns doctrine).
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  const ListSkeletonLoader({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHigh,
      highlightColor: scheme.surfaceContainerHighest,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => Container(
          height: 84,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.lgRadius,
          ),
        ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
