import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../ai/ai_error_translator.dart';
import '../providers/locale_providers.dart';
import '../theme/app_tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'state_views.dart';

/// A bottom sheet that shows the result of a one-shot AI action
/// (summarize, key points, find dates, generate flashcards, etc.),
/// driven by an [AsyncValue] the caller provides via [resultProvider].
/// Shared between Materials and Notes so the loading/error/result
/// presentation never drifts between the two features.
class AiResultSheet extends ConsumerWidget {
  final String title;
  final ProviderListenable<AsyncValue<String>> resultProvider;
  final VoidCallback? onSave;

  const AiResultSheet({
    super.key,
    required this.title,
    required this.resultProvider,
    this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required ProviderListenable<AsyncValue<String>> resultProvider,
    VoidCallback? onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.82,
        child: AiResultSheet(title: title, resultProvider: resultProvider, onSave: onSave),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final result = ref.watch(resultProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                if (result.hasValue) ...[
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.copy),
                    tooltip: l10n.copy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.value!));
                    },
                  ),
                  if (onSave != null)
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.bookmarkSimple),
                      tooltip: l10n.save,
                      onPressed: onSave,
                    ),
                ],
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Expanded(
              child: result.when(
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.generating, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                error: (err, st) => ErrorStateView(
                  message: AiErrorTranslator.translate(err, localeCode: localeCode).message,
                ),
                data: (text) => SingleChildScrollView(
                  child: MarkdownBody(data: text, selectable: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
