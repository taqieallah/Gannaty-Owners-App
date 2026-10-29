import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../shared/widgets/client_page_scaffold.dart';
import '../../../shared/widgets/skeleton.dart';

/// Security, maintenance and management contacts, set from the admin app.
class ImportantNumbersScreen extends ConsumerWidget {
  const ImportantNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbersAsync = ref.watch(importantNumbersProvider);
    final settings =
        ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.importantNumbers,
      body: numbersAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noImportantNumbers,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          // Keep the admin's order inside each group; groups in a fixed order.
          final groups = [
            for (final g in ImportantNumber.groupOrder)
              (g, items.where((n) => n.group == g).toList()),
          ].where((e) => e.$2.isNotEmpty).toList();

          return ListView(
            children: [
              for (final (group, numbers) in groups) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 4,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Text(
                    t.importantNumberGroup(group),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final n in numbers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NumberCard(number: n, t: t),
                  ),
              ],
            ],
          );
        },
        loading: () => const SkeletonList(),
        error: (error, stackTrace) =>
            Center(child: Text(t.failedLoadImportantNumbers)),
      ),
    );
  }
}

IconData _groupIcon(String group) => switch (group) {
  'security' => Icons.shield_rounded,
  'maintenance' => Icons.build_rounded,
  'management' => Icons.business_center_rounded,
  'emergency' => Icons.emergency_rounded,
  _ => Icons.call_rounded,
};

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.number, required this.t});

  final ImportantNumber number;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(_groupIcon(number.group), color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number.name, style: text.titleSmall),
                  if (number.role.isNotEmpty)
                    Text(
                      number.role,
                      style: text.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    number.phone,
                    textDirection: TextDirection.ltr,
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: t.whatsapp,
              icon: const Icon(Icons.chat_rounded),
              onPressed: () => launchUrl(
                Uri.parse('https://wa.me/${number.whatsappDigits}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: t.call,
              icon: const Icon(Icons.call_rounded),
              onPressed: () => launchUrl(
                Uri(scheme: 'tel', path: number.phone.replaceAll(' ', '')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
