/// Payload passed via `state.extra` when navigating to `/focus/session`
/// from the setup screen. `homeworkId`/`homeworkTitle`/`subjectName`/
/// `subjectKey` are null when the student chose "just study, no
/// specific homework" (product spec §20).
class FocusSessionArgs {
  final String? homeworkId;
  final String? homeworkTitle;
  final String? subjectId;
  final String? subjectKey;
  final String? subjectName;
  final int durationMinutes;

  const FocusSessionArgs({
    this.homeworkId,
    this.homeworkTitle,
    this.subjectId,
    this.subjectKey,
    this.subjectName,
    required this.durationMinutes,
  });
}
