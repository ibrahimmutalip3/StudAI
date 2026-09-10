import '../../../core/database/tables.dart';

/// Payload passed via `state.extra` when navigating to `/ai-tutor` from
/// another feature (Homework detail, Materials, Notes) so the AI Tutor
/// opens pre-scoped to that context, per product spec's
/// "context-aware AI" requirement — the student shouldn't have to
/// re-explain what they're working on.
class AiTutorLaunchArgs {
  final AiMode? mode;
  final String? subjectKey;
  final String? subjectName;
  final String? topic;
  final String? homeworkText;
  final String? notesExcerpt;
  final String? materialExcerpt;

  const AiTutorLaunchArgs({
    this.mode,
    this.subjectKey,
    this.subjectName,
    this.topic,
    this.homeworkText,
    this.notesExcerpt,
    this.materialExcerpt,
  });
}

enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
      );
}
