import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/admin_contact.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';
import '../../../shared/widgets/skeleton.dart';

/// Thousands-separated whole amount (125000 -> 125,000) so big balances read.
String _egp(num v) => NumberFormat('#,##0').format(v);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    final requests = ref.watch(serviceRequestsProvider);
    final settings =
        ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.home,
      body: ListView(
        children: [
          // ── Welcome / balance hero ──────────────────────────────────────
          accountAsync.when(
            data: (account) => _WelcomeCard(
              title: t.gannatyCompound,
              welcome: t.welcome,
              balanceLabel: t.balance,
              subtitle: t.homeHeroSubtitle,
              villaName: villa?.ownerName ?? '',
              villaNumber: account?.villaNo ?? villa?.villaNumber ?? '',
              balance: account?.balance ?? 0,
              isCredit: account?.isCredit ?? false,
            ),
            loading: () => _WelcomeCard(
              title: t.gannatyCompound,
              welcome: t.welcome,
              balanceLabel: t.balance,
              subtitle: t.homeHeroSubtitle,
              villaName: villa?.ownerName ?? '',
              villaNumber: villa?.villaNumber ?? '',
              balance: 0,
              isCredit: false,
              loading: true,
            ),
            error: (_, __) => _WelcomeCard(
              title: t.gannatyCompound,
              welcome: t.welcome,
              balanceLabel: t.balance,
              subtitle: t.homeHeroSubtitle,
              villaName: villa?.ownerName ?? '',
              villaNumber: villa?.villaNumber ?? '',
              balance: 0,
              isCredit: false,
            ),
          ),
          const SizedBox(height: 16),

          // ── Year selector ───────────────────────────────────────────────
          ref
              .watch(ownerStatementYearsProvider)
              .maybeWhen(
                data: (years) {
                  if (years.isEmpty) return const SizedBox.shrink();
                  final sel = ref.watch(selectedOwnerYearProvider);
                  final items = years.contains(sel) ? years : [sel, ...years]
                    ..sort((a, b) => b.compareTo(a));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: AppTheme.cognac,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${t.forYear}:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value: sel,
                          underline: const SizedBox.shrink(),
                          items: items
                              .map(
                                (y) => DropdownMenuItem<int>(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (y) {
                            if (y != null) {
                              ref
                                  .read(selectedOwnerYearProvider.notifier)
                                  .set(y);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

          // ── Owner account metric cards ──────────────────────────────────
          accountAsync.when(
            data: (account) {
              final bal = account?.balance ?? 0;
              final maintenance = account?.maintenance ?? 0;
              final payments = account?.totalPayments ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: t.maintenance,
                      value: _egp(maintenance),
                      color: AppTheme.cognac,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: t.payments,
                      value: _egp(payments),
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: t.balance,
                      value: _egp(bal.abs()),
                      color: bal <= 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SkeletonList(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          if ((accountAsync.asData?.value?.balance ?? 0) > 0.01) ...[
            _DuesReminder(
              amount: accountAsync.asData!.value!.balance,
              isArabic: settings.isArabic,
            ),
            const SizedBox(height: 16),
          ],
          requests.when(
            data: (items) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.requestStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _RequestBadge(
                          label: t.pending,
                          count: items
                              .where((e) => e.status.name == 'pending')
                              .length,
                          color: AppTheme.gold,
                        ),
                        _RequestBadge(
                          label: t.inProgress,
                          count: items
                              .where((e) => e.status.name == 'inProgress')
                              .length,
                          color: AppTheme.cognac,
                        ),
                        _RequestBadge(
                          label: t.solved,
                          count: items
                              .where((e) => e.status.name == 'solved')
                              .length,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SkeletonList(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.quickActions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        icon: Icons.add_circle_rounded,
                        label: t.newRequest,
                        onTap: () => context.push('/requests/new'),
                      ),
                      _QuickAction(
                        icon: Icons.notifications_rounded,
                        label: t.notifications,
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.title,
    required this.welcome,
    required this.balanceLabel,
    required this.subtitle,
    required this.villaName,
    required this.villaNumber,
    required this.balance,
    required this.isCredit,
    this.loading = false,
  });

  final String title;
  final String welcome;
  final String balanceLabel;
  final String subtitle;
  final String villaName;
  final String villaNumber;
  final double balance;
  final bool isCredit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isCredit
              ? [const Color(0xFF1A5C2D), AppTheme.success]
              : [const Color(0xFF5C2D1A), AppTheme.cognac],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            villaNumber.isEmpty ? title : '$title • فيلا $villaNumber',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            balanceLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loading ? '—' : '${_egp(balance.abs())} EGP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!loading)
            Text(
              isCredit ? 'دائن ✓' : (balance == 0 ? 'مسوّى' : 'مدين'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 18),
          Text(
            villaName.isEmpty ? welcome : '$welcome $villaName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuesReminder extends StatelessWidget {
  const _DuesReminder({required this.amount, required this.isArabic});
  final double amount;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppTheme.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تذكير بالمستحقات' : 'Outstanding Balance',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  isArabic
                      ? 'عليك مبلغ ${_egp(amount.abs())} جنيه — تواصل مع الإدارة للسداد.'
                      : 'You owe ${_egp(amount.abs())} EGP — contact management to make a payment.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            tooltip: isArabic ? 'تواصل عبر واتساب' : 'Contact via WhatsApp',
            icon: const Icon(Icons.chat_rounded),
            onPressed: () => AdminContact.openWhatsApp(
              message: isArabic
                  ? 'السلام عليكم، أرغب في الاستفسار/السداد لمستحقات فيلا.'
                  : 'Hello, I would like to inquire about or pay my villa balance.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestBadge extends StatelessWidget {
  const _RequestBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
