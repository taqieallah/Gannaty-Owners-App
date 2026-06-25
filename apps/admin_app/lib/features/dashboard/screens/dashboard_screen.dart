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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final villasAsync = ref.watch(villasProvider);
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final requestsAsync = ref.watch(allRequestsProvider);

    return AppScaffold(
      title: l10n.dashboardTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: l10n.logout,
          onPressed: () => ref.read(authServiceProvider).signOut(),
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: () async {
          ref.invalidate(villasProvider);
          ref.invalidate(allPaymentsProvider);
          ref.invalidate(allRequestsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 20, AppSpacing.screenH, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting banner ───────────────────────────────────────
              _GreetingBanner(paymentsAsync: paymentsAsync, l10n: l10n),
              const SizedBox(height: AppSpacing.xxl),

              // ── Stats grid ────────────────────────────────────────────
              GdsSectionHeader(title: l10n.overview),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: villasAsync.when(
                      data: (v) => GdsStatCard(
                        icon: Icons.villa_outlined,
                        value: '${v.length}',
                        label: l10n.totalVillas,
                        color: AppColors.navy,
                        onTap: () => context.go('/villas'),
                      ),
                      loading: () => const GdsStatCardSkeleton(),
                      error: (_, __) => const GdsStatCardSkeleton(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: paymentsAsync.when(
                      data: (p) => GdsStatCard(
                        icon: Icons.warning_amber_rounded,
                        value: '${p.where((x) => !x.isPaid).length}',
                        label: l10n.pendingPayments,
                        color: AppColors.warning,
                        onTap: () => context.go('/payments'),
                      ),
                      loading: () => const GdsStatCardSkeleton(),
                      error: (_, __) => const GdsStatCardSkeleton(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: requestsAsync.when(
                      data: (r) {
                        final open = r
                            .where((x) =>
                                x.status != ServiceRequestStatus.solved)
                            .length;
                        return GdsStatCard(
                          icon: Icons.build_outlined,
                          value: '$open',
                          label: l10n.openRequests,
                          color: AppColors.error,
                          onTap: () => context.go('/requests'),
                        );
                      },
                      loading: () => const GdsStatCardSkeleton(),
                      error: (_, __) => const GdsStatCardSkeleton(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: requestsAsync.when(
                      data: (r) {
                        final done = r
                            .where((x) =>
                                x.status == ServiceRequestStatus.solved)
                            .length;
                        return GdsStatCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '$done',
                          label: l10n.resolved,
                          color: AppColors.success,
                          onTap: () => context.go('/requests'),
                        );
                      },
                      loading: () => const GdsStatCardSkeleton(),
                      error: (_, __) => const GdsStatCardSkeleton(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Quick Actions ─────────────────────────────────────────
              GdsSectionHeader(title: l10n.quickActions),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.villa_outlined,
                      label: l10n.addVilla,
                      onTap: () => context.go('/villas/add'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_card_outlined,
                      label: l10n.addPayment,
                      onTap: () => context.go('/payments/add'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.calculate_outlined,
                      label: l10n.settlement,
                      onTap: () => context.go('/settlements'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Recent Requests ────────────────────────────────────────
              requestsAsync.when(
                data: (requests) {
                  final recent = requests.take(6).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GdsSectionHeader(
                        title: l10n.recentRequests,
                        action: l10n.viewAll,
                        onAction: () => context.go('/requests'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (recent.isEmpty)
                        GdsEmptyState(
                          icon: Icons.build_outlined,
                          title: l10n.noRequestsYet,
                          subtitle: l10n.requestsWillAppear,
                        )
                      else
                        ...recent.map((r) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: _RequestCard(
                                request: r,
                                l10n: l10n,
                                onTap: () => context
                                    .go('/requests/${r.id}'),
                              ),
                            )),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GdsSectionHeader(title: l10n.recentRequests),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(
                        3,
                        (_) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: _RequestCardSkeleton(),
                            )),
                  ],
                ),
                error: (e, _) => Text('${l10n.error}: $e',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting / Summary Banner ─────────────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final AppL10n l10n;
  const _GreetingBanner(
      {required this.paymentsAsync, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final hour = DateTime.now().hour;
    final greeting = l10n.greeting(hour);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white.withOpacity(0.65))),
                  Text(l10n.greetingAdmin,
                      style: AppTextStyles.titleLg
                          .copyWith(color: Colors.white)),
                ],
              ),
            ],
          ),
          paymentsAsync.maybeWhen(
            data: (payments) {
              final totalPaid = payments
                  .where((p) => p.isPaid)
                  .fold<double>(0, (s, p) => s + p.amount);
              final overdueCount =
                  payments.where((p) => p.isOverdue).length;
              return Column(
                children: [
                  const SizedBox(height: 18),
                  const Divider(
                      color: Colors.white24, height: 1, thickness: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _BannerStat(
                        label: l10n.totalCollected,
                        value:
                            '${fmt.format(totalPaid)} ${l10n.currencySuffix}',
                      ),
                      _BannerDivider(),
                      _BannerStat(
                        label: l10n.overdue,
                        value: l10n.pendingPaymentsCount(overdueCount),
                        valueColor: overdueCount > 0
                            ? const Color(0xFFFFD28A)
                            : Colors.white,
                      ),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _BannerStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.titleSm
                  .copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// ── Quick Action Button ────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GdsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navyPale,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.labelSm,
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }
}

// ── Request Card ───────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;
  final AppL10n l10n;
  const _RequestCard(
      {required this.request, required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final chipVariant = request.status == ServiceRequestStatus.solved
        ? GdsChipVariant.paid
        : request.status == ServiceRequestStatus.inProgress
            ? GdsChipVariant.inProgress
            : GdsChipVariant.pending;
    final chipLabel = request.status == ServiceRequestStatus.solved
        ? l10n.resolved
        : request.status == ServiceRequestStatus.inProgress
            ? l10n.inProgress
            : l10n.pending;

    return GdsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.navyPale,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(
              _typeIcon(request.type),
              color: AppColors.navyMid,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.villaNum(request.villaNumber),
                    style: AppTextStyles.titleSm),
                const SizedBox(height: 2),
                Text(request.description,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GdsStatusChip(variant: chipVariant, label: chipLabel),
        ],
      ),
    );
  }

  IconData _typeIcon(ServiceRequestType type) {
    switch (type) {
      case ServiceRequestType.maintenance:
        return Icons.build_outlined;
      case ServiceRequestType.complaint:
        return Icons.report_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class _RequestCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GdsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GdsShimmer(width: 38, height: 38, radius: AppRadius.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GdsShimmer(width: 100, height: 14),
                const SizedBox(height: 6),
                GdsShimmer(width: 180, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GdsShimmer(width: 64, height: 24, radius: 6),
        ],
      ),
    );
  }
}
