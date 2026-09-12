import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../shared/widgets/client_page_scaffold.dart';
import '../providers/notification_history_provider.dart';

String _bucketOf(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'اليوم';
  if (diff == 1) return 'أمس';
  if (diff < 7) return 'هذا الأسبوع';
  return 'أقدم';
}

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.notifications,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          tooltip: t.clearNotifications,
          onPressed: () => ref
              .read(notificationHistoryProvider.notifier)
              .clear(),
        ),
      ],
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noNotificationsYet,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          final children = <Widget>[];
          String? current;
          for (final entry in entries) {
            final b = _bucketOf(entry.receivedAt);
            if (b != current) {
              current = b;
              children.add(Padding(
                padding: EdgeInsets.only(
                    top: children.isEmpty ? 4 : 18, bottom: 8, right: 4),
                child: Text(
                  b,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                ),
              ));
            }
            children.add(Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationTile(entry: entry),
            ));
          }
          return ListView(children: children);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry});

  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('yyyy/MM/dd - hh:mm a').format(entry.receivedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
