import 'package:drift/drift.dart';

/// ---------------------------------------------------------------------
/// DATABASE CHOICE — Drift (SQLite)
/// ---------------------------------------------------------------------
/// Rationale (see DESIGN.md decisions log):
///
/// This app's core domain — Homework, Lesson, Schedule, Test, TestQuestion,
/// StudySession — is fundamentally RELATIONAL: a Homework belongs to a
/// Subject, has many linked Materials/Notes, a Test has many
/// TestQuestions, a StudySession references a Homework or Subject, etc.
/// Filtering (Today / Overdue / This week / Subject), joins (statistics
/// aggregated across subjects and time), and referential integrity
/// (deleting a Subject should cascade sensibly) are all things a
/// relational engine does natively and efficiently.
///
/// Isar is excellent for large flexible-schema object stores, but this
/// app's read patterns are exactly SQL's strength: "sum study minutes by
/// subject this week", "homework due today ordered by priority", "tests
/// completed this month". Drift gives compile-time-checked SQL, a real
/// migration story (SQL schema versioning), and reactive Streams per
/// query — which map directly onto Riverpod's StreamProvider without any
/// adapter layer. It also keeps us on plain SQLite, which every platform
/// (incl. iOS/Android CI runners) supports without native plugin risk.
///
/// Conclusion: Drift is the better fit for this app's shape. Isar would
/// be preferable for a media-gallery-style or document-store-style app;
/// this is not that.
/// ---------------------------------------------------------------------

/// Subjects — both the fixed curriculum list and any user-added ones.
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get key => text()(); // stable key, e.g. 'history_of_armenia'
  TextColumn get displayNameEn => text()();
  TextColumn get displayNameRu => text()();
  TextColumn get displayNameHy => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User settings — single-row table.
class UserSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get gradeLevel => text().withDefault(const Constant(''))();
  TextColumn get localeCode => text().withDefault(const Constant('en'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get hasCompletedOnboarding =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderMinutesBeforeDeadline =>
      integer().withDefault(const Constant(60))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Weekly recurring lesson (schedule).
class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  IntColumn get dayOfWeek => integer()(); // 1 = Monday .. 7 = Sunday
  TextColumn get startTime => text()(); // "HH:mm"
  TextColumn get endTime => text()(); // "HH:mm"
  TextColumn get room => text().withDefault(const Constant(''))();
  TextColumn get teacher => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

enum HomeworkStatus { pending, inProgress, completed, overdue }

enum HomeworkPriority { low, medium, high }

class Homeworks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get topic => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get priority =>
      textEnum<HomeworkPriority>().withDefault(const Constant('medium'))();
  TextColumn get status =>
      textEnum<HomeworkStatus>().withDefault(const Constant('pending'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  // JSON-encoded list of local file paths (images/PDFs attached).
  TextColumn get attachmentPaths => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum MaterialType { pdf, image, text, note }

class StudyMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get topic => text().withDefault(const Constant(''))();
  TextColumn get type => textEnum<MaterialType>()();
  TextColumn get filePath => text().withDefault(const Constant(''))();
  TextColumn get textContent => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get imagePaths => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  IntColumn get timesReviewed => integer().withDefault(const Constant(0))();
  IntColumn get timesCorrect => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class FlashcardDecks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

enum TestQuestionType { multipleChoice, trueFalse, shortAnswer }

class Tests extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get topic => text().withDefault(const Constant(''))();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get lastScoreCorrect => integer().nullable()();
  IntColumn get lastScoreTotal => integer().nullable()();
  DateTimeColumn get lastTakenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TestQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get testId => text().references(Tests, #id)();
  TextColumn get type => textEnum<TestQuestionType>()();
  TextColumn get prompt => text()();
  // JSON-encoded list of option strings (empty for shortAnswer).
  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text().withDefault(const Constant(''))();
  TextColumn get userAnswer => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

enum AiMode {
  explain,
  solveTogether,
  solution,
  checkAnswer,
  simplify,
  generateTest,
  imageRecognition,
}

class AiConversations extends Table {
  TextColumn get id => text()();
  TextColumn get mode => textEnum<AiMode>()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  TextColumn get contextTitle => text().withDefault(const Constant(''))();
  // JSON-encoded list of {role, content, timestamp}.
  TextColumn get messagesJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SavedAiResponses extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().nullable().references(AiConversations, #id)();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

enum StudySessionType { focusMode, general }

class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  TextColumn get homeworkId => text().nullable().references(Homeworks, #id)();
  TextColumn get type => textEnum<StudySessionType>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
