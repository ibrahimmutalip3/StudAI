import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/ai_tutor_launch_args.dart';

/// A single chat bubble — user or assistant. Assistant messages render
/// Markdown (the AI is instructed to use light formatting for steps/
/// emphasis) while user messages stay plain text. Fades and slides in
/// on first build, per DESIGN.md's "staggered fade+slide per message
/// bubble" motion signature.
class AiMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onSave;
  final VoidCallback? onCopy;
  final VoidCallback? onSpeak;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onSave,
    this.onCopy,
    this.onSpeak,
  });

  @override
  State<AiMessageBubble> createState() => _AiMessageBubbleState();
}

class _AiMessageBubbleState extends State<AiMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.standard);
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUser = widget.message.role == ChatRole.user;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.82,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? scheme.primary
                      : (widget.message.isError
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : scheme.surfaceContainerLow),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadii.lg),
                    topRight: const Radius.circular(AppRadii.lg),
                    bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.sm),
                    bottomRight: Radius.circular(isUser ? AppRadii.sm : AppRadii.lg),
                  ),
                ),
                child: isUser
                    ? Text(
                        widget.message.content,
                        style: textTheme.bodyLarge?.copyWith(color: scheme.onPrimary),
                      )
                    : MarkdownBody(
                        data: widget.message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: textTheme.bodyLarge?.copyWith(
                            color: widget.message.isError ? AppColors.danger : scheme.onSurface,
                          ),
                          strong: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                          listBullet: textTheme.bodyLarge,
                          h1: textTheme.titleLarge,
                          h2: textTheme.titleMedium,
                          h3: textTheme.titleSmall,
                          code: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor: scheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
              ),
              if (!isUser && !widget.message.isError)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onSpeak != null)
                        _MiniAction(icon: PhosphorIconsRegular.speakerHigh, onTap: widget.onSpeak!),
                      if (widget.onCopy != null)
                        _MiniAction(icon: PhosphorIconsRegular.copy, onTap: widget.onCopy!),
                      if (widget.onSave != null)
                        _MiniAction(icon: PhosphorIconsRegular.bookmarkSimple, onTap: widget.onSave!),
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

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
