import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(serviceRequestsProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.requests,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/new'),
        backgroundColor: AppTheme.cognac,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.newRequest),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(child: Text(t.noRequestsYet));
          }

          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => context.push('/requests/${requests[index].id}'),
                child: _RequestCard(request: requests[index], t: t),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('${t.failedLoadRequests}: $error'),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.t});

  final ServiceRequest request;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('yyyy/MM/dd - hh:mm a').format(request.createdAt);
    final statusColor = switch (request.status) {
      ServiceRequestStatus.pending => AppTheme.gold,
      ServiceRequestStatus.inProgress => AppTheme.cognac,
      ServiceRequestStatus.solved => AppTheme.success,
    };
    final statusLabel = switch (request.status) {
      ServiceRequestStatus.pending => t.pending,
      ServiceRequestStatus.inProgress => t.inProgress,
      ServiceRequestStatus.solved => t.solved,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _typeLabel(request.type),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: statusColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 8),
            Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),
            if ((request.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, color: AppTheme.cognac),
                    const SizedBox(width: 10),
                    Expanded(child: Text(request.adminNote!)),
                  ],
                ),
              ),
            ],
            if ((request.imageUrl ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                request.status == ServiceRequestStatus.solved
                    ? t.afterRepairPhoto
                    : t.progressPhoto,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(request.imageUrl!, fit: BoxFit.contain),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      request.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Text(t.failedLoadImage),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(ServiceRequestType type) {
    switch (type) {
      case ServiceRequestType.maintenance:
        return t.maintenance;
      case ServiceRequestType.complaint:
        return t.complaint;
      case ServiceRequestType.other:
        return t.other;
    }
  }
}
