import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables.dart';
import '../../../core/providers/dao_providers.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/focus_session_args.dart';

enum FocusTimerStatus { running, paused, ended }

class FocusSessionState {
  final FocusTimerStatus status;
  final Duration elapsed;

  const FocusSessionState({this.status = FocusTimerStatus.running, this.elapsed = Duration.zero});

  FocusSessionState copyWith({FocusTimerStatus? status, Duration? elapsed}) {
    return FocusSessionState(status: status ?? this.status, elapsed: elapsed ?? this.elapsed);
  }
}

/// Drives the Focus Mode countdown/count-up and records a
/// [StudySession] row so the time contributes to Statistics. The timer
/// counts *up* from zero even though the student picked a target
/// duration — the target is shown as a goal, not a hard cutoff, so a
/// student who wants to keep going after the bell isn't cut off
/// mid-thought.
class FocusSessionController extends StateNotifier<FocusSessionState> {
  final Ref _ref;
  final FocusSessionArgs args;
  Timer? _ticker;
  String? _sessionId;

  FocusSessionController(this._ref, this.args) : super(const FocusSessionState()) {
    _start();
  }

  Future<void> _start() async {
    final dao = _ref.read(studySessionDaoProvider);
    _sessionId = IdGenerator.next();
    await dao.startSession(
      StudySessionsCompanion(
        id: Value(_sessionId!),
        subjectId: Value(args.subjectId),
        homeworkId: Value(args.homeworkId),
        type: const Value(StudySessionType.focusMode),
        startedAt: Value(DateTime.now()),
      ),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != FocusTimerStatus.running) return;
      state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
    });
  }

  void pause() {
    if (state.status != FocusTimerStatus.running) return;
    state = state.copyWith(status: FocusTimerStatus.paused);
  }

  void resume() {
    if (state.status != FocusTimerStatus.paused) return;
    state = state.copyWith(status: FocusTimerStatus.running);
  }

  Future<void> end() async {
    _ticker?.cancel();
    state = state.copyWith(status: FocusTimerStatus.ended);
    if (_sessionId != null) {
      await _ref.read(studySessionDaoProvider).endSession(
            _sessionId!,
            durationSeconds: state.elapsed.inSeconds,
          );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final focusSessionControllerProvider =
    StateNotifierProvider.autoDispose.family<FocusSessionController, FocusSessionState, FocusSessionArgs>(
  (ref, args) => FocusSessionController(ref, args),
);
