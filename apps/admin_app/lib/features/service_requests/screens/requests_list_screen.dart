import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/ds_components.dart';

class RequestsListScreen extends ConsumerStatefulWidget {
  const RequestsListScreen({super.key});
  @override
  ConsumerState<RequestsListScreen> createState() =>
      _RequestsListScreenState();
}

class _RequestsListScreenState extends ConsumerState<RequestsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<ServiceRequest> _filter(
      List<ServiceRequest> all, ServiceRequestStatus? status) {
    if (status == null) return all;
    return all.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final requestsAsync = ref.watch(allRequestsProvider);

    return AppScaffold(
      title: l10n.requestsTitle,
      bottom: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: l10n.all),
          Tab(text: l10n.pending),
          Tab(text: l10n.inProgress),
          Tab(text: l10n.resolved),
        ],
      ),
      body: requestsAsync.when(
        data: (all) => TabBarView(
          controller: _tab,
          children: [
            _RequestList(requests: all, l10n: l10n),
            _RequestList(
                requests: _filter(all, ServiceRequestStatus.pending),
                l10n: l10n),
            _RequestList(
                requests:
                    _filter(all, ServiceRequestStatus.inProgress),
                l10n: l10n),
            _RequestList(
                requests: _filter(all, ServiceRequestStatus.solved),
                l10n: l10n),
          ],
        ),
        loading: () => const GdsLoading(),
        error: (e, _) => Center(
          child: Text('${l10n.error}: $e',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<ServiceRequest> requests;
  final AppL10n l10n;
  const _RequestList({required this.requests, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return GdsEmptyState(
        icon: Icons.build_outlined,
        title: l10n.noRequestsYet,
        subtitle: l10n.noRequestsInCategory,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 16, AppSpacing.screenH, 32),
      itemCount: requests.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _RequestCard(request: requests[i], l10n: l10n),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final AppL10n l10n;
  const _RequestCard({required this.request, required this.l10n});

  GdsChipVariant get _chipVariant {
    switch (request.status) {
      case ServiceRequestStatus.pending:
        return GdsChipVariant.pending;
      case ServiceRequestStatus.inProgress:
        return GdsChipVariant.inProgress;
      case ServiceRequestStatus.solved:
        return GdsChipVariant.paid;
    }
  }

  String _chipLabel() {
    switch (request.status) {
      case ServiceRequestStatus.pending:
        return l10n.pending;
      case ServiceRequestStatus.inProgress:
        return l10n.inProgress;
      case ServiceRequestStatus.solved:
        return l10n.resolved;
    }
  }

  Color get _typeColor {
    switch (request.type) {
      case ServiceRequestType.maintenance:
        return AppColors.navyMid;
      case ServiceRequestType.complaint:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (request.type) {
      case ServiceRequestType.maintenance:
        return Icons.build_outlined;
      case ServiceRequestType.complaint:
        return Icons.report_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GdsCard(
      onTap: () => context.go('/requests/${request.id}'),
      padding: const EdgeInsets.all(14),
      highlighted: request.status == ServiceRequestStatus.inProgress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l10n.villaNum(request.villaNumber),
                        style: AppTextStyles.titleSm),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(request.type.label,
                          style: AppTextStyles.chip
                              .copyWith(color: _typeColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(request.description,
                    style: AppTextStyles.bodySm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd MMM yyyy – HH:mm')
                      .format(request.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GdsStatusChip(variant: _chipVariant, label: _chipLabel()),
        ],
      ),
    );
  }
}
