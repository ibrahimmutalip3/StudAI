import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dao_providers.dart';
import '../widgets/app_shell.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/today_screen.dart';
import '../../features/homework/presentation/screens/homework_list_screen.dart';
import '../../features/homework/presentation/screens/homework_detail_screen.dart';
import '../../features/homework/presentation/screens/homework_capture_screen.dart';
import '../../features/homework/presentation/screens/homework_edit_screen.dart';
import '../../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../../features/materials/presentation/screens/materials_hub_screen.dart';
import '../../features/materials/presentation/screens/material_detail_screen.dart';
import '../../features/materials/presentation/screens/material_add_screen.dart';
import '../../features/materials/presentation/screens/pdf_viewer_screen.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/flashcards/presentation/screens/flashcard_decks_screen.dart';
import '../../features/flashcards/presentation/screens/flashcard_study_screen.dart';
import '../../features/tests/presentation/screens/tests_list_screen.dart';
import '../../features/tests/presentation/screens/test_generator_screen.dart'
    show TestGeneratorScreen, TestGeneratorArgs;
import '../../features/tests/presentation/screens/test_taking_screen.dart';
import '../../features/tests/presentation/screens/test_results_screen.dart';
import '../../features/schedule/presentation/screens/schedule_screen.dart';
import '../../features/focus/presentation/screens/focus_setup_screen.dart';
import '../../features/focus/presentation/screens/focus_session_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

/// Root navigator key kept outside the shell so full-screen routes
/// (Focus Mode, homework capture) can push above the bottom nav.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// NOTE ON CODE GENERATION: these two providers are hand-written (not
/// `@riverpod`-annotated) on purpose. riverpod_generator's analyzer-based
/// annotation resolver has a known crash ("Could not resolve annotation
/// for ...") on very large, deeply-nested top-level functions — and this
/// file's route tree is exactly that shape. Every other provider in the
/// app still uses `@riverpod` code generation as normal; this file is the
/// sole, deliberate exception. Functionally these are identical to what
/// the generator would have produced.
final onboardingStatusProvider = StreamProvider<bool>((ref) {
  final dao = ref.watch(settingsDaoProvider);
  return dao.watch().map((s) => s.hasCompletedOnboarding);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final settingsAsync = ref.watch(onboardingStatusProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/today',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final hasOnboarded = settingsAsync.valueOrNull;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (hasOnboarded == false && !goingToOnboarding) return '/onboarding';
      if (hasOnboarded == true && goingToOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: '/homework',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeworkListScreen()),
            routes: [
              GoRoute(
                path: 'capture',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const HomeworkCaptureScreen(),
              ),
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as HomeworkEditArgs?;
                  return HomeworkEditScreen(prefill: extra);
                },
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => HomeworkDetailScreen(
                  homeworkId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => HomeworkEditScreen(
                      homeworkId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/ai-tutor',
            pageBuilder: (context, state) {
              final extra = state.extra as AiTutorLaunchArgs?;
              return NoTransitionPage(child: AiTutorScreen(launchArgs: extra));
            },
          ),
          GoRoute(
            path: '/materials',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MaterialsHubScreen()),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const MaterialAddScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => MaterialDetailScreen(
                  materialId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id/pdf',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final extra = state.extra as Map<String, String>?;
                  return PdfViewerScreen(
                    filePath: extra?['filePath'] ?? '',
                    title: extra?['title'] ?? '',
                  );
                },
              ),
              GoRoute(
                path: 'notes',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const NotesListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => NoteEditorScreen(
                      noteId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'flashcards',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const FlashcardDecksScreen(),
                routes: [
                  GoRoute(
                    path: ':deckId/study',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => FlashcardStudyScreen(
                      deckId: state.pathParameters['deckId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'tests',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const TestsListScreen(),
                routes: [
                  GoRoute(
                    path: 'generate',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final args = extra == null
                          ? null
                          : TestGeneratorArgs(
                              subjectId: extra['subjectId'] as String?,
                              topic: extra['topic'] as String?,
                            );
                      return TestGeneratorScreen(args: args);
                    },
                  ),
                  GoRoute(
                    path: ':id/take',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => TestTakingScreen(
                      testId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id/results',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => TestResultsScreen(
                      testId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'schedule',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
            routes: [
              GoRoute(
                path: 'statistics',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/focus/setup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FocusSetupScreen(),
      ),
      GoRoute(
        path: '/focus/session',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as FocusSessionArgs;
          return FocusSessionScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
