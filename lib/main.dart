import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers/network_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/providers/auth_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Wire the network layer's session-expiry hook to the auth state so a
      // failed token refresh signs the user out app-wide (spec §10, §12).
      overrides: <Override>[
        sessionExpiredHandlerProvider.overrideWith(
          (ref) => ref.watch(authSessionExpiryHandlerProvider),
        ),
      ],
      child: const DigitalSusuApp(),
    ),
  );
}

/// Digital Susu V2 application root (Phase 1 bootstrap).
class DigitalSusuApp extends ConsumerWidget {
  const DigitalSusuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      // `en-GH` is the configured business locale (AppConfig.locale), but
      // flutter_localizations ships no en-GH table, so Material widgets
      // localize to `en` while numbers/dates use explicit Ghana-first
      // formatters (spec §2).
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
