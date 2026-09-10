import '../../../core/database/tables.dart';

/// Extra payload passed via `state.extra` when pushing to
/// `/homework/new`, used to prefill fields (e.g. from AI image
/// recognition results, or "create homework from this material").
class HomeworkEditArgs {
  final String? title;
  final String? subjectId;
  final String? topic;
  final String? description;
  final DateTime? deadline;
  final HomeworkPriority? priority;
  final List<String>? attachmentPaths;

  const HomeworkEditArgs({
    this.title,
    this.subjectId,
    this.topic,
    this.description,
    this.deadline,
    this.priority,
    this.attachmentPaths,
  });
}
