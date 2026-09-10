import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/database/tables.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../application/ai_tutor_controller.dart';
import '../../domain/ai_tutor_launch_args.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_mode_selector.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  final AiTutorLaunchArgs? launchArgs;
  const AiTutorScreen({super.key, this.launchArgs});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.standard,
        curve: AppMotion.enter,
      );
    });
  }

  void _send(AiTutorController controller) {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    controller.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = ref.watch(isOnlineProvider);
    final state = ref.watch(aiTutorControllerProvider(widget.launchArgs));
    final controller = ref.read(aiTutorControllerProvider(widget.launchArgs).notifier);

    ref.listen(aiTutorControllerProvider(widget.launchArgs), (prev, next) {
      if (next.messages.length != prev?.messages.length) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.aiTutorTitle),
            if (state.subjectName != null)
              Text(
                state.topic?.isNotEmpty == true
                    ? '${state.subjectName} · ${state.topic}'
                    : state.subjectName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash),
              tooltip: l10n.aiClearChat,
              onPressed: () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AiModeSelector(
              selected: state.mode,
              onChanged: (mode) => controller.setMode(mode),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !isOnline
                ? OfflineStateView(onRetry: () => setState(() {}))
                : state.messages.isEmpty
                    ? _EmptyState(
                        onTapMode: () => _showModeSheet(context, state, controller),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.messages.length + (state.isSending ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index >= state.messages.length) {
                            return const _TypingIndicator();
                          }
                          final message = state.messages[index];
                          return AiMessageBubble(
                            message: message,
                            onCopy: message.role == ChatRole.assistant
                                ? () => _copy(context, message.content)
                                : null,
                            onSave: message.role == ChatRole.assistant
                                ? () => _save(context, ref, message.content, state)
                                : null,
                          );
                        },
                      ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: _ErrorBanner(
                message: state.errorMessage!,
                retryable: state.errorIsRetryable,
                onRetry: controller.retryLast,
              ),
            ),
          _InputBar(
            controller: _inputController,
            enabled: isOnline && !state.isSending,
            onSend: () => _send(controller),
            onCamera: () => context.push('/homework/capture'),
          ),
        ],
      ),
    );
  }

  void _showModeSheet(BuildContext context, AiTutorState state, AiTutorController controller) {
    showModalBottomSheet(
      context: context,
      builder: (_) => AiModeSheet(selected: state.mode, onSelected: controller.setMode),
    );
  }

  void _confirmClear(BuildContext context, AiTutorController controller) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiClearChat),
        content: Text(l10n.aiClearChatConfirm),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              controller.clearConversation();
              context.pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.aiResponseSaved)),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String content,
    AiTutorState state,
  ) async {
    final dao = ref.read(aiDaoProvider);
    await dao.saveResponse(
      SavedAiResponsesCompanion(
        id: Value(IdGenerator.next()),
        title: Value(state.topic?.isNotEmpty == true
            ? state.topic!
            : (state.subjectName ?? 'AI Tutor')),
        content: Value(content),
        subjectId: Value(state.subjectKey),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.aiResponseSaved)),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTapMode;
  const _EmptyState({required this.onTapMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: PhosphorIconsRegular.sparkle,
      title: l10n.aiEmptyStateTitle,
      subtitle: l10n.aiEmptyStateSubtitle,
      actionLabel: l10n.aiChooseMode,
      onAction: onTapMode,
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.lg),
            topRight: const Radius.circular(AppRadii.lg),
            bottomRight: const Radius.circular(AppRadii.lg),
            bottomLeft: const Radius.circular(AppRadii.sm),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.aiThinking, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool retryable;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.retryable, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warningCircle, color: scheme.onErrorContainer, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
          if (retryable)
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.tryAgain, style: TextStyle(color: scheme.onErrorContainer)),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onCamera;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: enabled ? onCamera : null,
              icon: const Icon(PhosphorIconsRegular.camera),
              tooltip: l10n.aiCameraAttach,
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: AppRadii.pillRadius,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.aiSendHint,
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: enabled ? onSend : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: AppTouchTarget.min,
                  height: AppTouchTarget.min,
                  child: Icon(PhosphorIconsBold.arrowUp, color: scheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
