import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_core/core.dart';

import 'core/config/app_config.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/locale_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No-op if SYNCFUSION_LICENSE_KEY wasn't provided at build time — the PDF
  // viewer still works, just with a small unlicensed-build watermark. See
  // AppConfig.syncfusionLicenseKey for how to configure a free key.
  if (AppConfig.syncfusionLicenseKey.isNotEmpty) {
    SyncfusionLicense.registerLicense(AppConfig.syncfusionLicenseKey);
  }
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: StudAiApp()));
}

class StudAiApp extends ConsumerWidget {
  const StudAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'StudAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
