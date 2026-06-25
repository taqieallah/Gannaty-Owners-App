import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(serviceRequestsProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.requestDetail,
      body: requestsAsync.when(
        data: (requests) {
          final request = requests.where((r) => r.id == requestId).firstOrNull;
          if (request == null) {
            return Center(child: Text(t.failedLoadRequests));
          }
          return _RequestDetailBody(request: request, t: t);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(t.failedLoadRequests)),
      ),
    );
  }
}

class _RequestDetailBody extends StatelessWidget {
  const _RequestDetailBody({required this.request, required this.t});

  final ServiceRequest request;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _StatusStepper(status: request.status, t: t),
        const SizedBox(height: 16),
        _InfoCard(request: request, t: t),
        if ((request.adminNote ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _AdminNoteCard(note: request.adminNote!, t: t),
        ],
        if ((request.imageUrl ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _PhotoCard(
            imageUrl: request.imageUrl!,
            label: request.status == ServiceRequestStatus.solved
                ? t.afterRepairPhoto
                : t.progressPhoto,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status, required this.t});

  final ServiceRequestStatus status;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: t.pending, icon: Icons.hourglass_empty_rounded),
      (label: t.inProgress, icon: Icons.build_rounded),
      (label: t.solved, icon: Icons.check_circle_rounded),
    ];
    final currentIndex = status.index;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.statusTimeline,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  // Connector line
                  final lineIndex = i ~/ 2;
                  final filled = lineIndex < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: filled
                          ? AppTheme.cognac
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  );
                }
                final stepIndex = i ~/ 2;
                final step = steps[stepIndex];
                final isCompleted = stepIndex < currentIndex;
                final isCurrent = stepIndex == currentIndex;
                final color = isCompleted || isCurrent
                    ? AppTheme.cognac
                    : Theme.of(context).colorScheme.outlineVariant;

                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isCompleted || isCurrent)
                            ? AppTheme.cognac.withValues(alpha: 0.12)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isCurrent ? 2.5 : 1.5,
                        ),
                      ),
                      child: Icon(step.icon, size: 20, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.request, required this.t});

  final ServiceRequest request;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    final createdStr =
        DateFormat('yyyy/MM/dd - hh:mm a').format(request.createdAt);
    final updatedStr =
        DateFormat('yyyy/MM/dd - hh:mm a').format(request.updatedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(label: t.requestType, value: _typeLabel(request.type, t)),
            const SizedBox(height: 10),
            Text(
              t.issueDescription,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(request.description),
            ),
            const SizedBox(height: 14),
            _Row(label: t.submittedOn, value: createdStr),
            const SizedBox(height: 6),
            _Row(label: t.lastUpdated, value: updatedStr),
          ],
        ),
      ),
    );
  }

  String _typeLabel(ServiceRequestType type, AppText t) {
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AdminNoteCard extends StatelessWidget {
  const _AdminNoteCard({required this.note, required this.t});

  final String note;
  final AppText t;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes_rounded, color: AppTheme.cognac),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظة الإدارة',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(note),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
