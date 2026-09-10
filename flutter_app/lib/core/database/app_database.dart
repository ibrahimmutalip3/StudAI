import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/subject_dao.dart';
import 'daos/homework_dao.dart';
import 'daos/lesson_dao.dart';
import 'daos/note_dao.dart';
import 'daos/material_dao.dart';
import 'daos/flashcard_dao.dart';
import 'daos/test_dao.dart';
import 'daos/ai_dao.dart';
import 'daos/study_session_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Subjects,
    UserSettingsTable,
    Lessons,
    Homeworks,
    StudyMaterials,
    Notes,
    Flashcards,
    FlashcardDecks,
    Tests,
    TestQuestions,
    AiConversations,
    SavedAiResponses,
    StudySessions,
  ],
  daos: [
    SubjectDao,
    HomeworkDao,
    LessonDao,
    NoteDao,
    MaterialDao,
    FlashcardDao,
    TestDao,
    AiDao,
    StudySessionDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor used by tests to inject an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultSubjects(this);
          await into(userSettingsTable).insert(
            const UserSettingsTableCompanion(),
            mode: InsertMode.insertOrIgnore,
          );
        },
        onUpgrade: (m, from, to) async {
          // Future schema migrations land here, versioned.
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'study_assistant.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Seeds the fixed curriculum subject list from the product spec,
/// including full Armenian/Russian/English localized names. Users can
/// still add custom subjects (isCustom = true) on top of this.
Future<void> _seedDefaultSubjects(AppDatabase db) async {
  final defaults = <SubjectsCompanion>[
    _subject('mathematics', 'Mathematics', 'Математика', 'Մաթեմատիկա',
        '0xFF5B6EE8', 0),
    _subject('algebra', 'Algebra', 'Алгебра', 'Հանրահաշիվ', '0xFF5B6EE8', 1),
    _subject('geometry', 'Geometry', 'Геометрия', 'Երկրաչափություն',
        '0xFF5B6EE8', 2),
    _subject('physics', 'Physics', 'Физика', 'Ֆիզիկա', '0xFF4CAF7D', 3),
    _subject('chemistry', 'Chemistry', 'Химия', 'Քիմիա', '0xFF4CAF7D', 4),
    _subject('biology', 'Biology', 'Биология', 'Կենսաբանություն',
        '0xFF4CAF7D', 5),
    _subject('geography', 'Geography', 'География', 'Աշխարհագրություն',
        '0xFF4CAF7D', 6),
    _subject('computer_science', 'Computer Science', 'Информатика',
        'Ինֆորմատիկա', '0xFF5B6EE8', 7),
    _subject('history', 'History', 'История', 'Պատմություն', '0xFFC77B4C', 8),
    _subject('history_of_armenia', 'History of Armenia',
        'История Армении', 'Հայոց պատմություն', '0xFFC77B4C', 9),
    _subject('world_history', 'World History', 'Всемирная история',
        'Համաշխարհային պատմություն', '0xFFC77B4C', 10),
    _subject('armenian_language', 'Armenian Language', 'Армянский язык',
        'Հայոց լեզու', '0xFFB05FC2', 11),
    _subject('armenian_literature', 'Armenian Literature',
        'Армянская литература', 'Հայ գրականություն', '0xFFE0637A', 12),
    _subject('russian_language', 'Russian Language', 'Русский язык',
        'Ռուսաց լեզու', '0xFFB05FC2', 13),
    _subject('russian_literature', 'Russian Literature',
        'Русская литература', 'Ռուս գրականություն', '0xFFE0637A', 14),
    _subject('english', 'English', 'Английский язык', 'Անգլերեն',
        '0xFFB05FC2', 15),
    _subject('social_studies', 'Social Studies', 'Обществознание',
        'Հասարակագիտություն', '0xFF5B9EE8', 16),
    _subject('other', 'Other', 'Другое', 'Այլ', '0xFF8A8F98', 17),
  ];

  await db.batch((batch) {
    batch.insertAll(db.subjects, defaults, mode: InsertMode.insertOrIgnore);
  });
}

SubjectsCompanion _subject(
  String key,
  String en,
  String ru,
  String hy,
  String colorHex,
  int order,
) {
  return SubjectsCompanion.insert(
    id: key,
    key: key,
    displayNameEn: en,
    displayNameRu: ru,
    displayNameHy: hy,
    colorHex: colorHex,
    isCustom: const Value(false),
    sortOrder: Value(order),
  );
}
