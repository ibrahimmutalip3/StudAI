import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Add/edit form for a weekly recurring [Lesson]. Shown as a modal
/// bottom sheet from the Schedule screen, reused for both create (no
/// [existing]) and edit (pass the lesson row to prefill).
class LessonFormSheet extends ConsumerStatefulWidget {
  final Lesson? existing;
  const LessonFormSheet({super.key, this.existing});

  static Future<void> show(BuildContext context, WidgetRef ref, {Lesson? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LessonFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends ConsumerState<LessonFormSheet> {
  String? _subjectId;
  int _dayOfWeek = DateTime.now().weekday;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 45);
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _subjectId = existing.subjectId;
      _dayOfWeek = existing.dayOfWeek;
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
      _roomController.text = existing.room;
      _teacherController.text = existing.teacher;
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _roomController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (_subjectId == null) return;
    final id = widget.existing?.id ?? IdGenerator.next();
    await ref.read(lessonDaoProvider).upsert(
          LessonsCompanion(
            id: Value(id),
            subjectId: Value(_subjectId!),
            dayOfWeek: Value(_dayOfWeek),
            startTime: Value(_formatTime(_startTime)),
            endTime: Value(_formatTime(_endTime)),
            room: Value(_roomController.text.trim()),
            teacher: Value(_teacherController.text.trim()),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? l10n.addLesson : l10n.editLesson,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              StreamBuilder<List<Subject>>(
                stream: subjectsAsync,
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? const <Subject>[];
                  return DropdownButtonFormField<String>(
                    initialValue: _subjectId,
                    decoration: InputDecoration(labelText: l10n.lessonSubject),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName(localeCode))))
                        .toList(),
                    onChanged: (v) => setState(() => _subjectId = v),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: InputDecoration(labelText: l10n.lessonDay),
                items: List.generate(7, (i) => i + 1)
                    .map((d) => DropdownMenuItem(value: d, child: Text(AppDateUtils.weekdayName(d, localeCode))))
                    .toList(),
                onChanged: (v) => setState(() => _dayOfWeek = v ?? _dayOfWeek),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartTime,
                      child: Text('${l10n.lessonStartTime}: ${_formatTime(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndTime,
                      child: Text('${l10n.lessonEndTime}: ${_formatTime(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(labelText: l10n.lessonRoom),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _teacherController,
                decoration: InputDecoration(labelText: l10n.lessonTeacher),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _subjectId == null ? null : _save,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
