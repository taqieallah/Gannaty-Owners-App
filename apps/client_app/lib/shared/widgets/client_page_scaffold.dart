import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/app_text.dart';
import '../../core/theme/app_theme.dart';
import 'app_settings_sheet.dart';

class ClientPageScaffold extends ConsumerWidget {
  const ClientPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF140D09)
        : AppTheme.ivory;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => showAppSettingsSheet(context),
            icon: const Icon(Icons.tune_rounded),
            tooltip: t.appSettings,
          ),
          ...?actions,
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
