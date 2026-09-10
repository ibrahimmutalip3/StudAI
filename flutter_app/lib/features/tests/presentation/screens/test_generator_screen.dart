import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../ai_tutor/application/ai_tutor_controller.dart';

/// Optional pre-fill (e.g. reached from a Material's "Make a test"
/// action, which already knows the subject/topic).
class TestGeneratorArgs {
  final String? subjectId;
  final String? topic;
  const TestGeneratorArgs({this.subjectId, this.topic});
}

class TestGeneratorScreen extends ConsumerStatefulWidget {
  final TestGeneratorArgs? args;
  const TestGeneratorScreen({super.key, this.args});

  @override
  ConsumerState<TestGeneratorScreen> createState() => _TestGeneratorScreenState();
}

enum _Difficulty { easy, medium, hard }

class _TestGeneratorScreenState extends ConsumerState<TestGeneratorScreen> {
  final _topicController = TextEditingController();
  String? _subjectId;
  _Difficulty _difficulty = _Difficulty.medium;
  int _questionCount = 8;
  final Set<String> _questionTypes = {'multiple_choice', 'true_false', 'short_answer'};
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.args?.subjectId;
    if (widget.args?.topic != null) _topicController.text = widget.args!.topic!;
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String _difficultyKey(_Difficulty d) => switch (d) {
        _Difficulty.easy => 'easy',
        _Difficulty.medium => 'medium',
        _Difficulty.hard => 'hard',
      };

  Future<void> _generate(List<Subject> subjects) async {
    final l10n = AppLocalizations.of(context)!;
    final subject = subjects.where((s) => s.id == _subjectId).firstOrNull;
    if (subject == null || _topicController.text.trim().isEmpty || _questionTypes.isEmpty) return;

    setState(() => _generating = true);
    try {
      final localeCode = ref.read(localeCodeProvider);
      final testId = await ref.read(
        testGenerationProvider(
          TestGenerationRequest(
            subjectId: subject.id,
            subjectName: subject.displayName(localeCode),
            topic: _topicController.text.trim(),
            difficulty: _difficultyKey(_difficulty),
            questionCount: _questionCount,
            questionTypes: _questionTypes.toList(),
          ),
        ).future,
      );
      if (mounted) {
        context.pushReplacement('/materials/tests/$testId/take');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();
    final localeCode = ref.watch(localeCodeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.generateTest)),
      body: _generating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.generatingTest, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : StreamBuilder<List<Subject>>(
              stream: subjectsAsync,
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? const <Subject>[];
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
                  ),
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _subjectId,
                      decoration: InputDecoration(labelText: l10n.testSubject),
                      items: subjects
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName(localeCode))))
                          .toList(),
                      onChanged: (v) => setState(() => _subjectId = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _topicController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.testTopic, hintText: l10n.testTopicHint),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(l10n.testDifficulty, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<_Difficulty>(
                      segments: [
                        ButtonSegment(value: _Difficulty.easy, label: Text(l10n.difficultyEasy)),
                        ButtonSegment(value: _Difficulty.medium, label: Text(l10n.difficultyMedium)),
                        ButtonSegment(value: _Difficulty.hard, label: Text(l10n.difficultyHard)),
                      ],
                      selected: {_difficulty},
                      onSelectionChanged: (s) => setState(() => _difficulty = s.first),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(l10n.testQuestionCount, style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 3,
                      max: 15,
                      divisions: 12,
                      label: '$_questionCount',
                      onChanged: (v) => setState(() => _questionCount = v.round()),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.testQuestionTypes, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        FilterChip(
                          label: Text(l10n.typeMultipleChoice),
                          selected: _questionTypes.contains('multiple_choice'),
                          onSelected: (v) => setState(() =>
                              v ? _questionTypes.add('multiple_choice') : _questionTypes.remove('multiple_choice')),
                        ),
                        FilterChip(
                          label: Text(l10n.typeTrueFalse),
                          selected: _questionTypes.contains('true_false'),
                          onSelected: (v) => setState(
                              () => v ? _questionTypes.add('true_false') : _questionTypes.remove('true_false')),
                        ),
                        FilterChip(
                          label: Text(l10n.typeShortAnswer),
                          selected: _questionTypes.contains('short_answer'),
                          onSelected: (v) => setState(
                              () => v ? _questionTypes.add('short_answer') : _questionTypes.remove('short_answer')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: (_subjectId == null ||
                              _topicController.text.trim().isEmpty ||
                              _questionTypes.isEmpty)
                          ? null
                          : () => _generate(subjects),
                      child: Text(l10n.generateTest),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
