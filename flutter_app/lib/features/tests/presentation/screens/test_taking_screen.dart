import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestTakingScreen({super.key, required this.testId});

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen> {
  int _index = 0;
  final Map<String, String> _answers = {};
  final _shortAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A fresh attempt starts clean, in case this test was retaken.
    ref.read(testDaoProvider).resetAnswers(widget.testId);
  }

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _selectAnswer(TestQuestion question, String answer) {
    setState(() => _answers[question.id] = answer);
  }

  Future<void> _next(List<TestQuestion> questions) async {
    final question = questions[_index];
    final answer = question.type == TestQuestionType.shortAnswer
        ? _shortAnswerController.text.trim()
        : _answers[question.id];
    if (answer == null || answer.isEmpty) return;

    await ref.read(testDaoProvider).recordAnswer(question.id, answer);

    if (_index >= questions.length - 1) {
      await _finish(questions);
      return;
    }
    setState(() {
      _index++;
      _shortAnswerController.clear();
    });
  }

  Future<void> _finish(List<TestQuestion> questions) async {
    var correct = 0;
    for (final q in questions) {
      final given = q.id == questions[_index].id
          ? (q.type == TestQuestionType.shortAnswer ? _shortAnswerController.text.trim() : _answers[q.id])
          : q.userAnswer;
      if (given != null && given.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
        correct++;
      }
    }
    await ref.read(testDaoProvider).recordScore(widget.testId, correct, questions.length);
    if (mounted) {
      context.pushReplacement('/materials/tests/${widget.testId}/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questionsAsync = ref.watch(testDaoProvider).watchQuestions(widget.testId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<TestQuestion>>(
        stream: questionsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final questions = snapshot.data!;
          if (questions.isEmpty) return const SizedBox.shrink();
          final question = questions[_index.clamp(0, questions.length - 1)];
          final options = (jsonDecode(question.optionsJson) as List).map((e) => e.toString()).toList();
          final canProceed = question.type == TestQuestionType.shortAnswer
              ? _shortAnswerController.text.trim().isNotEmpty
              : _answers[question.id] != null;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _index / questions.length,
                  borderRadius: AppRadii.pillRadius,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.questionOf(_index + 1, questions.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    child: question.type == TestQuestionType.shortAnswer
                        ? TextField(
                            controller: _shortAnswerController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: l10n.yourAnswerLabel,
                              hintText: l10n.yourAnswerHint,
                            ),
                            onChanged: (_) => setState(() {}),
                          )
                        : Column(
                            children: options
                                .map((opt) => _OptionTile(
                                      label: opt,
                                      selected: _answers[question.id] == opt,
                                      onTap: () => _selectAnswer(question, opt),
                                    ))
                                .toList(),
                          ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canProceed ? () => _next(questions) : null,
                    child: Text(_index >= questions.length - 1 ? l10n.finishTest : l10n.nextQuestion),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: AppRadii.mdRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: AppIconSize.md,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
