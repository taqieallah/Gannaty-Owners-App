import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/app_text.dart';
import '../../core/theme/app_theme.dart';

class AppSettingsSheet extends ConsumerWidget {
  const AppSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.appSettings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Text(t.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(value: true, label: Text(t.arabic)),
              ButtonSegment<bool>(value: false, label: Text(t.english)),
            ],
            selected: {settings.isArabic},
            onSelectionChanged: (value) {
              ref.read(appSettingsProvider.notifier).setLanguage(value.first);
            },
          ),
          const SizedBox(height: 18),
          Text(t.theme, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(t.light),
                icon: const Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(t.dark),
                icon: const Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) {
              ref.read(appSettingsProvider.notifier).setThemeMode(value.first);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> showAppSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.mist,
    showDragHandle: true,
    builder: (_) => const AppSettingsSheet(),
  );
}
