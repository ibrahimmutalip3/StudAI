import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../ai_tutor/domain/ai_tutor_launch_args.dart';
import '../../application/focus_session_controller.dart';
import '../../domain/focus_session_args.dart';

export '../../domain/focus_session_args.dart' show FocusSessionArgs;

class FocusSessionScreen extends ConsumerWidget {
  final FocusSessionArgs args;
  const FocusSessionScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(focusSessionControllerProvider(args));
    final controller = ref.read(focusSessionControllerProvider(args).notifier);

    final targetSeconds = args.durationMinutes * 60;
    final progress = targetSeconds == 0 ? 0.0 : (state.elapsed.inSeconds / targetSeconds).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd(context, ref, controller);
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () => _confirmEnd(context, ref, controller),
                    ),
                  ],
                ),
                const Spacer(),
                if (args.homeworkTitle != null) ...[
                  Text(
                    args.subjectName ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    args.homeworkTitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: scheme.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation(scheme.primary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppDateUtils.clockDuration(state.elapsed),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          if (state.status == FocusTimerStatus.paused) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(l10n.focusPaused, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmEnd(context, ref, controller),
                      icon: const Icon(PhosphorIconsRegular.stop),
                      label: Text(l10n.focusEnd),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: state.status == FocusTimerStatus.paused ? controller.resume : controller.pause,
                      icon: Icon(
                        state.status == FocusTimerStatus.paused ? PhosphorIconsFill.play : PhosphorIconsFill.pause,
                      ),
                      label: Text(
                        state.status == FocusTimerStatus.paused ? l10n.focusResume : l10n.focusPause,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: () => _openAiHelp(context, ref),
                  icon: const Icon(PhosphorIconsRegular.sparkle),
                  label: Text(l10n.focusAiHelp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAiHelp(BuildContext context, WidgetRef ref) {
    context.push(
      '/ai-tutor',
      extra: AiTutorLaunchArgs(
        subjectKey: args.subjectKey,
        subjectName: args.subjectName,
        homeworkText: args.homeworkTitle,
      ),
    );
  }

  Future<void> _confirmEnd(
    BuildContext context,
    WidgetRef ref,
    FocusSessionController controller,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(focusSessionControllerProvider(args));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.focusEndConfirmTitle),
        content: Text(l10n.focusEndConfirmBody),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => context.pop(true), child: Text(l10n.focusEnd)),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.end();
    if (!context.mounted) return;

    final localeCode = ProviderScope.containerOf(context).read(localeCodeProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.focusSessionSavedTitle),
        content: Text(l10n.focusSessionSavedBody(AppDateUtils.friendlyDuration(state.elapsed, localeCode))),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
    if (context.mounted) context.go('/today');
  }
}
