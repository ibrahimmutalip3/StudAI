import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/app_database.dart';
import '../ai/ai_service.dart';
import '../ai/gemini_ai_service.dart';

/// Single app-wide database instance. Overridden in tests with an
/// in-memory database via ProviderScope overrides.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Single app-wide AI service instance, bound to the abstract interface
/// so it can be swapped/mocked without touching feature code.
final aiServiceProvider = Provider<AIService>((ref) {
  final service = GeminiAIService();
  ref.onDispose(service.dispose);
  return service;
});

/// Live connectivity stream — used by the offline banner and to gate AI
/// actions across every feature.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

/// Simple derived boolean: is the device currently online (best-effort;
/// does not guarantee the AI endpoint itself is reachable, only that a
/// network interface reports connectivity).
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    orElse: () => true, // optimistic until first event arrives
  );
});
