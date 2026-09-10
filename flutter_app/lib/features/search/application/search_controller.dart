import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/homework_dao.dart';
import '../../../core/database/daos/test_dao.dart';
import '../../../core/providers/dao_providers.dart';

/// The query text currently typed into the search field. Kept as plain
/// state (not debounced itself) so the text field never lags behind
/// keystrokes; debouncing happens downstream in [searchResultsProvider].
final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchResults {
  final List<HomeworkWithSubject> homework;
  final List<Note> notes;
  final List<StudyMaterial> materials;
  final List<FlashcardDeck> flashcardDecks;
  final List<TestWithSubject> tests;
  final List<SavedAiResponse> savedResponses;

  const SearchResults({
    this.homework = const [],
    this.notes = const [],
    this.materials = const [],
    this.flashcardDecks = const [],
    this.tests = const [],
    this.savedResponses = const [],
  });

  bool get isEmpty =>
      homework.isEmpty &&
      notes.isEmpty &&
      materials.isEmpty &&
      flashcardDecks.isEmpty &&
      tests.isEmpty &&
      savedResponses.isEmpty;

  int get totalCount =>
      homework.length +
      notes.length +
      materials.length +
      flashcardDecks.length +
      tests.length +
      savedResponses.length;
}

/// Debounced, cross-feature search. Homework and Tests don't have a
/// dedicated `search()` DAO method (their tables are small and always
/// loaded via `watchAll()` for filtering/statistics), so those two are
/// matched client-side against the already-loaded list; Notes,
/// Materials, FlashcardDecks, and SavedAiResponses use their DAOs'
/// SQL `LIKE` search directly.
final searchResultsProvider = FutureProvider.autoDispose<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const SearchResults();

  // Debounce: wait briefly so fast typing doesn't fire a query per
  // keystroke. If the query changes again before this fires, Riverpod
  // disposes this provider instance (autoDispose) and the delayed work
  // is simply discarded rather than producing a stale result.
  await Future<void>.delayed(const Duration(milliseconds: 250));

  final homeworkDao = ref.read(homeworkDaoProvider);
  final noteDao = ref.read(noteDaoProvider);
  final materialDao = ref.read(materialDaoProvider);
  final flashcardDao = ref.read(flashcardDaoProvider);
  final testDao = ref.read(testDaoProvider);
  final aiDao = ref.read(aiDaoProvider);

  final lower = query.toLowerCase();

  final allHomework = await homeworkDao.watchAll().first;
  final matchedHomework = allHomework
      .where((h) =>
          h.homework.title.toLowerCase().contains(lower) ||
          h.homework.description.toLowerCase().contains(lower) ||
          h.homework.topic.toLowerCase().contains(lower))
      .toList();

  final allTests = await testDao.watchAll().first;
  final matchedTests = allTests
      .where((t) =>
          t.test.title.toLowerCase().contains(lower) ||
          t.test.topic.toLowerCase().contains(lower))
      .toList();

  final allDecks = await flashcardDao.watchDecks().first;
  final matchedDecks =
      allDecks.where((d) => d.title.toLowerCase().contains(lower)).toList();

  final results = await Future.wait([
    noteDao.search(query),
    materialDao.search(query),
    aiDao.search(query),
  ]);

  return SearchResults(
    homework: matchedHomework,
    notes: results[0] as List<Note>,
    materials: results[1] as List<StudyMaterial>,
    flashcardDecks: matchedDecks,
    tests: matchedTests,
    savedResponses: results[2] as List<SavedAiResponse>,
  );
});
