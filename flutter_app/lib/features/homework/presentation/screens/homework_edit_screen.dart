import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/homework_edit_args.dart';

class HomeworkEditScreen extends ConsumerStatefulWidget {
  final String? homeworkId;
  final HomeworkEditArgs? prefill;

  const HomeworkEditScreen({super.key, this.homeworkId, this.prefill});

  bool get isEditing => homeworkId != null;

  @override
  ConsumerState<HomeworkEditScreen> createState() => _HomeworkEditScreenState();
}

class _HomeworkEditScreenState extends ConsumerState<HomeworkEditScreen> {
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _subjectId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  HomeworkPriority _priority = HomeworkPriority.medium;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null) {
      _titleController.text = prefill.title ?? '';
      _topicController.text = prefill.topic ?? '';
      _descriptionController.text = prefill.description ?? '';
      _subjectId = prefill.subjectId;
      _deadline = prefill.deadline ?? _deadline;
      _priority = prefill.priority ?? _priority;
    }
    if (widget.isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(homeworkDaoProvider);
    final existing = await dao.getById(widget.homeworkId!);
    if (existing != null && mounted) {
      setState(() {
        _titleController.text = existing.title;
        _topicController.text = existing.topic;
        _descriptionController.text = existing.description;
        _subjectId = existing.subjectId;
        _deadline = existing.deadline;
        _priority = existing.priority;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.edit : l10n.addHomework),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: subjectsAsync,
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? const <Subject>[];
          if (subjects.isNotEmpty && _subjectId == null) {
            _subjectId = subjects.first.id;
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.homeworkTitle),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _subjectId,
                decoration: const InputDecoration(),
                items: subjects
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.displayName(localeCode)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _subjectId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              _DeadlinePicker(
                deadline: _deadline,
                localeCode: localeCode,
                onChanged: (value) => setState(() => _deadline = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _PriorityPicker(
                priority: _priority,
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.homeworkTitle)),
      );
      return;
    }
    final dao = ref.read(homeworkDaoProvider);
    final id = widget.homeworkId ?? IdGenerator.next();

    await dao.upsert(
      HomeworksCompanion(
        id: Value(id),
        title: Value(_titleController.text.trim()),
        subjectId: Value(_subjectId!),
        topic: Value(_topicController.text.trim()),
        description: Value(_descriptionController.text.trim()),
        deadline: Value(_deadline),
        priority: Value(_priority),
      ),
    );

    if (mounted) context.pop();
  }
}

class _DeadlinePicker extends StatelessWidget {
  final DateTime deadline;
  final String localeCode;
  final ValueChanged<DateTime> onChanged;

  const _DeadlinePicker({
    required this.deadline,
    required this.localeCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: AppRadii.mdRadius,
      child: InkWell(
        borderRadius: AppRadii.mdRadius,
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.calendar),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('${l10n.deadline}: ${deadline.toLocal()}'.split('.').first)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(deadline),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

class _PriorityPicker extends StatelessWidget {
  final HomeworkPriority priority;
  final ValueChanged<HomeworkPriority> onChanged;
  const _PriorityPicker({required this.priority, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.priorityLow),
            selected: priority == HomeworkPriority.low,
            onSelected: (_) => onChanged(HomeworkPriority.low),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.priorityMedium),
            selected: priority == HomeworkPriority.medium,
            onSelected: (_) => onChanged(HomeworkPriority.medium),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.priorityHigh),
            selected: priority == HomeworkPriority.high,
            onSelected: (_) => onChanged(HomeworkPriority.high),
          ),
        ),
      ],
    );
  }
}
