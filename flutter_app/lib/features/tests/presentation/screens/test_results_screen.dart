import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class TestResultsScreen extends ConsumerWidget {
  final String testId;
  const TestResultsScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final testDao = ref.watch(testDaoProvider);
    final questionsAsync = testDao.watchQuestions(testId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.testResultsTitle)),
      body: FutureBuilder<Test?>(
        future: testDao.getById(testId),
        builder: (context, testSnap) {
          final test = testSnap.data;
          return StreamBuilder<List<TestQuestion>>(
            stream: questionsAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData || test == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final questions = snapshot.data!;
              final correct = test.lastScoreCorrect ?? 0;
              final total = test.lastScoreTotal ?? questions.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
                ),
                children: [
                  _ScoreHeader(correct: correct, total: total),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.reviewAnswers, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  ...questions.map((q) => _QuestionReviewCard(question: q)),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pushReplacement('/materials/tests/$testId/take'),
                      child: Text(l10n.retakeTest),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int correct;
  final int total;
  const _ScoreHeader({required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final ratio = total == 0 ? 0.0 : correct / total;
    final color = ratio >= 0.7 ? AppColors.success : (ratio >= 0.4 ? AppColors.warning : AppColors.danger);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadii.lgRadius),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  backgroundColor: scheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('${(ratio * 100).round()}%', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.testScore(correct, total), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final TestQuestion question;
  const _QuestionReviewCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = question.userAnswer != null &&
        question.userAnswer!.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: isCorrect ? AppColors.success : AppColors.danger, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
                color: isCorrect ? AppColors.success : AppColors.danger,
                size: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(question.prompt, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (question.userAnswer != null && !isCorrect) ...[
            Text(
              '${l10n.yourAnswerLabel}: ${question.userAnswer}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '${l10n.correctAnswerLabel}: ${question.correctAnswer}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.explanationLabel}: ${question.explanation}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
