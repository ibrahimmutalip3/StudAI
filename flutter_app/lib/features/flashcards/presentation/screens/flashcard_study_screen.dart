import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final String deckId;
  const FlashcardStudyScreen({super.key, required this.deckId});

  @override
  ConsumerState<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  int _index = 0;
  bool _showingBack = false;
  int _reviewedCount = 0;
  bool _sessionComplete = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: AppMotion.standard);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showingBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showingBack = !_showingBack);
  }

  void _next(List<Flashcard> cards, {required bool knewIt}) {
    ref.read(flashcardDaoProvider).recordReview(cards[_index].id, correct: knewIt);
    _reviewedCount++;
    if (_index >= cards.length - 1) {
      setState(() => _sessionComplete = true);
      return;
    }
    _flipController.value = 0;
    setState(() {
      _index++;
      _showingBack = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _showingBack = false;
      _reviewedCount = 0;
      _sessionComplete = false;
    });
    _flipController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardsAsync = ref.watch(flashcardDaoProvider).watchCardsInDeck(widget.deckId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
          tooltip: l10n.backToDecks,
        ),
      ),
      body: StreamBuilder<List<Flashcard>>(
        stream: cardsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;
          if (cards.isEmpty) {
            return EmptyStateView(
              icon: PhosphorIconsRegular.cards,
              title: l10n.deckEmptyTitle,
            );
          }
          if (_sessionComplete) {
            return _CompletionView(
              reviewedCount: _reviewedCount,
              onRestart: _restart,
              onDone: () => context.pop(),
            );
          }
          final card = cards[_index.clamp(0, cards.length - 1)];
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_index) / cards.length,
                  borderRadius: AppRadii.pillRadius,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.questionOf(_index + 1, cards.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _flipController,
                      builder: (context, child) {
                        final angle = _flipController.value * 3.14159265;
                        final isBack = angle > 3.14159265 / 2;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(angle),
                          child: isBack
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(3.14159265),
                                  child: _CardFace(text: card.back, isBack: true),
                                )
                              : _CardFace(text: card.front, isBack: false),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_showingBack)
                  Text(l10n.flipCard, style: Theme.of(context).textTheme.bodySmall)
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _next(cards, knewIt: false),
                          icon: const Icon(PhosphorIconsRegular.x),
                          label: Text(l10n.didntKnowIt),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _next(cards, knewIt: true),
                          icon: const Icon(PhosphorIconsRegular.check),
                          label: Text(l10n.knewIt),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final bool isBack;
  const _CardFace({required this.text, required this.isBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isBack ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: AppRadii.xlRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isBack ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int reviewedCount;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  const _CompletionView({
    required this.reviewedCount,
    required this.onRestart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: const Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: AppIconSize.xl),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.studySessionComplete, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.studySessionCompleteBody(reviewedCount),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(onPressed: onRestart, child: Text(l10n.reviewAgain)),
                const SizedBox(width: AppSpacing.md),
                FilledButton(onPressed: onDone, child: Text(l10n.done)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
