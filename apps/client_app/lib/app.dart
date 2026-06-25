import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/notifications/client_notification_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/offline_banner.dart';

class ClientApp extends ConsumerWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GoogleFonts.config.allowRuntimeFetching = true;
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);

    return MaterialApp.router(
      title: 'Gannaty Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      routerConfig: router,
      builder: (context, child) {
        return ClientNotificationBootstrap(
          child: Directionality(
            textDirection: settings.textDirection,
            child: OfflineBanner(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
