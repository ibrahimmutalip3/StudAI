import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';
import '../database/daos/subject_dao.dart';
import '../database/daos/homework_dao.dart';
import '../database/daos/lesson_dao.dart';
import '../database/daos/note_dao.dart';
import '../database/daos/material_dao.dart';
import '../database/daos/flashcard_dao.dart';
import '../database/daos/test_dao.dart';
import '../database/daos/ai_dao.dart';
import '../database/daos/study_session_dao.dart';
import '../database/daos/settings_dao.dart';

final subjectDaoProvider = Provider<SubjectDao>(
  (ref) => ref.watch(appDatabaseProvider).subjectDao,
);

final homeworkDaoProvider = Provider<HomeworkDao>(
  (ref) => ref.watch(appDatabaseProvider).homeworkDao,
);

final lessonDaoProvider = Provider<LessonDao>(
  (ref) => ref.watch(appDatabaseProvider).lessonDao,
);

final noteDaoProvider = Provider<NoteDao>(
  (ref) => ref.watch(appDatabaseProvider).noteDao,
);

final materialDaoProvider = Provider<MaterialDao>(
  (ref) => ref.watch(appDatabaseProvider).materialDao,
);

final flashcardDaoProvider = Provider<FlashcardDao>(
  (ref) => ref.watch(appDatabaseProvider).flashcardDao,
);

final testDaoProvider = Provider<TestDao>(
  (ref) => ref.watch(appDatabaseProvider).testDao,
);

final aiDaoProvider = Provider<AiDao>(
  (ref) => ref.watch(appDatabaseProvider).aiDao,
);

final studySessionDaoProvider = Provider<StudySessionDao>(
  (ref) => ref.watch(appDatabaseProvider).studySessionDao,
);

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao,
);
