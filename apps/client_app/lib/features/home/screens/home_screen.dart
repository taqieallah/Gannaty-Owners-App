import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:compound_core/compound_core.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_type.dart';
import '../../../core/providers/app_providers.dart';
import '../../notifications/providers/notification_history_provider.dart';
import '../../../shared/widgets/ui.dart';
import '../../../shared/widgets/date_ar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    final requests = ref.watch(serviceRequestsProvider).asData?.value ?? const [];
    final announcements =
        ref.watch(announcementsProvider).asData?.value ?? const [];
    final txs =
        ref.watch(ownerTransactionsStreamProvider).asData?.value ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentBound(
          child: RefreshIndicator(
            color: AppColors.copper,
            onRefresh: () async {
              ref.invalidate(ownerAccountProvider);
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 90),
              children: [
                _Header(villa: villa),
                Gap.h20,
                accountAsync.when(
                  loading: () => const _BalanceSkeleton(),
                  error: (_, __) => _BalanceCard(account: null),
                  data: (a) => _BalanceCard(account: a),
                ),
                Gap.h20,
                const _QuickActions(),
                Gap.h24,
                _Maintenance(requests: requests),
                Gap.h24,
                _Announcements(items: announcements),
                Gap.h24,
                _Activity(txs: txs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  const _Header({required this.villa});
  final Villa? villa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final unread =
        ref.watch(notificationHistoryProvider).asData?.value.length ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مرحباً،',
                  style: t.bodyMedium?.copyWith(color: AppColors.inkSoft)),
              Gap.h4,
              Text(villa?.ownerName ?? 'عزيزي المالك',
                  style: t.titleLarge?.copyWith(fontSize: 20)),
              Gap.h4,
              Row(children: [
                const Icon(Icons.location_city_rounded,
                    size: 15, color: AppColors.copper),
                Gap.w4,
                Text(
                  'كمبوند جنتي • فيلا ${villa?.villaNumber ?? '—'}',
                  style: t.bodySmall,
                ),
              ]),
            ],
          ),
        ),
        _IconButtonBadge(
          icon: Icons.notifications_none_rounded,
          count: unread,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _IconButtonBadge extends StatelessWidget {
  const _IconButtonBadge(
      {required this.icon, required this.count, required this.onTap});
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.md,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: Radii.md,
          border: Border.all(color: cs.outline),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: cs.onSurface),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Balance summary ─────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.account});
  final OwnerAccount? account;

  @override
  Widget build(BuildContext context) {
    final a = account;
    final credit = a?.isCredit ?? false;
    final bal = (a?.balance ?? 0).abs();
    final statusText = a == null
        ? '—'
        : credit
            ? 'رصيد لصالحك'
            : bal < 0.01
                ? 'الحساب مسدّد بالكامل'
                : 'عليه مديونية';
    return Container(
      padding: const EdgeInsets.all(Gap.xxl),
      decoration: BoxDecoration(
        borderRadius: Radii.lg,
        gradient: const LinearGradient(
          colors: [AppColors.navySoft, AppColors.navyDeep],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('الرصيد الحالي',
                style: AppType.eyebrow(Colors.white.withValues(alpha: 0.75))),
            const Spacer(),
            _HeroStatus(text: statusText, credit: credit, settled: bal < 0.01),
          ]),
          Gap.h12,
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(money(bal), style: AppType.money(Colors.white, size: 34)),
              Gap.w8,
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('جنيه',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Gap.h20,
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          Gap.h16,
          Row(children: [
            _HeroStat(
                label: 'المدفوع هذا العام',
                value: money(a?.totalPayments ?? 0)),
            Container(
                width: 1, height: 30, color: Colors.white.withValues(alpha: 0.12)),
            _HeroStat(label: 'إجمالي الرسوم', value: money(a?.totalCharges ?? 0)),
          ]),
        ],
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus(
      {required this.text, required this.credit, required this.settled});
  final String text;
  final bool credit;
  final bool settled;
  @override
  Widget build(BuildContext context) {
    final color = settled || credit ? AppColors.success : AppColors.copperSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18), borderRadius: Radii.pill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Gap.w4,
        Text(text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5)),
          Gap.h4,
          Text('$value جنيه',
              style: AppType.num(Colors.white, size: 14.5)),
        ],
      ),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 180,
        decoration: BoxDecoration(
            borderRadius: Radii.lg, color: AppColors.navyDeep),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
            strokeWidth: 2.4, color: Colors.white54),
      );
}

// ── Quick actions ───────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: QuickAction(
              icon: Icons.receipt_long_rounded,
              label: 'كشف الحساب',
              onTap: () => context.go('/balance'))),
      Gap.w12,
      Expanded(
          child: QuickAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'طلب صيانة',
              onTap: () => context.push('/requests/new'))),
      Gap.w12,
      Expanded(
          child: QuickAction(
              icon: Icons.build_rounded,
              label: 'طلباتي',
              onTap: () => context.go('/requests'))),
      Gap.w12,
      Expanded(
          child: QuickAction(
              icon: Icons.campaign_rounded,
              label: 'الإعلانات',
              onTap: () => context.go('/announcements'))),
    ]);
  }
}

// ── Maintenance ─────────────────────────────────────────────────────────────
(String, BadgeTone) requestStatusView(ServiceRequestStatus s) => switch (s) {
      ServiceRequestStatus.pending => (s.label, BadgeTone.amber),
      ServiceRequestStatus.inProgress => (s.label, BadgeTone.info),
      ServiceRequestStatus.solved => (s.label, BadgeTone.success),
    };

class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.requests});
  final List<ServiceRequest> requests;
  @override
  Widget build(BuildContext context) {
    final active = requests
        .where((r) => r.status != ServiceRequestStatus.solved)
        .toList();
    final show = (active.isEmpty ? requests : active).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('طلبات الصيانة',
            actionLabel: requests.isEmpty ? null : 'عرض الكل',
            onAction: () => context.go('/requests')),
        if (show.isEmpty)
          AppCard(
            child: Row(children: [
              const Icon(Icons.handyman_outlined,
                  color: AppColors.inkSoft, size: 22),
              Gap.w12,
              const Expanded(
                  child: Text('لا توجد طلبات صيانة حالياً',
                      style: TextStyle(color: AppColors.inkSoft))),
              TextButton(
                  onPressed: () => context.push('/requests/new'),
                  child: const Text('طلب جديد')),
            ]),
          )
        else
          ...show.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: _RequestRow(r: r),
              )),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.r});
  final ServiceRequest r;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (label, tone) = requestStatusView(r.status);
    return AppCard(
      onTap: () => context.push('/requests/${r.id}'),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
              color: AppColors.copperTint, borderRadius: Radii.sm),
          child: const Icon(Icons.build_rounded,
              color: AppColors.copper, size: 20),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Gap.h4,
              Text(arDate(r.createdAt), style: t.bodySmall),
            ],
          ),
        ),
        Gap.w8,
        StatusBadge(label, tone: tone),
      ]),
    );
  }
}

// ── Announcements ───────────────────────────────────────────────────────────
class _Announcements extends StatelessWidget {
  const _Announcements({required this.items});
  final List<Announcement> items;
  @override
  Widget build(BuildContext context) {
    final show = items.take(2).toList();
    if (show.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('آخر الإعلانات',
            actionLabel: 'عرض الكل', onAction: () => context.go('/announcements')),
        ...show.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.go('/announcements'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                          color: AppColors.infoTint, borderRadius: Radii.sm),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.info, size: 20),
                    ),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Gap.h4,
                          Text(a.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall),
                          Gap.h8,
                          Text(arDate(a.createdAt),
                              style: t.labelSmall
                                  ?.copyWith(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ── Recent activity ─────────────────────────────────────────────────────────
class _Activity extends StatelessWidget {
  const _Activity({required this.txs});
  final List<OwnerLedgerEntry> txs;
  @override
  Widget build(BuildContext context) {
    final show = txs.take(4).toList();
    if (show.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('آخر النشاطات',
            actionLabel: 'كشف الحساب', onAction: () => context.go('/balance')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < show.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 68, endIndent: 16),
                _ActivityRow(e: show[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.e});
  final OwnerLedgerEntry e;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pay = e.isPayment;
    final color = pay ? AppColors.success : AppColors.danger;
    final tint = pay ? AppColors.successTint : AppColors.dangerTint;
    return Padding(
      padding: const EdgeInsets.all(Gap.lg),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: tint, borderRadius: Radii.sm),
          child: Icon(
              pay ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 19),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pay ? 'دفعة' : (e.category ?? 'رسوم'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Gap.h4,
              Text(arDateStr(e.txDate), style: t.bodySmall),
            ],
          ),
        ),
        Gap.w8,
        Text('${pay ? '+' : '−'}${money(e.amount)}',
            style: AppType.num(color, size: 15, weight: FontWeight.w800)),
      ]),
    );
  }
}
