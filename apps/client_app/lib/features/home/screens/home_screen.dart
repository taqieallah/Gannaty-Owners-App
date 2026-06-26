import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    final requests = ref.watch(serviceRequestsProvider);
    final settings = ref.watch(appSettingsProvider).value ??
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
          ref.watch(ownerStatementYearsProvider).maybeWhen(
                data: (years) {
                  if (years.isEmpty) return const SizedBox.shrink();
                  final sel = ref.watch(selectedOwnerYearProvider);
                  final items = years.contains(sel)
                      ? years
                      : [sel, ...years]
                    ..sort((a, b) => b.compareTo(a));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 20, color: AppTheme.cognac),
                        const SizedBox(width: 10),
                        Text('${t.forYear}:',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        DropdownButton<int>(
                          value: sel,
                          underline: const SizedBox.shrink(),
                          items: items
                              .map((y) => DropdownMenuItem<int>(
                                    value: y,
                                    child: Text('$y',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                  ))
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
                      title: 'الصيانة',
                      value: maintenance.toStringAsFixed(0),
                      color: AppTheme.cognac,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'المدفوعات',
                      value: payments.toStringAsFixed(0),
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'الرصيد',
                      value: bal.abs().toStringAsFixed(0),
                      color: bal <= 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
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
                          count: items.where((e) => e.status.name == 'pending').length,
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
                          count: items.where((e) => e.status.name == 'solved').length,
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
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
                        icon: Icons.receipt_long_rounded,
                        label: t.payments,
                        onTap: () => context.go('/payments'),
                      ),
                      _QuickAction(
                        icon: Icons.add_circle_rounded,
                        label: t.newRequest,
                        onTap: () => context.push('/requests/new'),
                      ),
                      _QuickAction(
                        icon: Icons.account_balance_wallet_rounded,
                        label: t.balance,
                        onTap: () => context.go('/balance'),
                      ),
                      _QuickAction(
                        icon: Icons.campaign_rounded,
                        label: t.announcements,
                        onTap: () => context.go('/announcements'),
                      ),
                      _QuickAction(
                        icon: Icons.notifications_rounded,
                        label: t.notifications,
                        onTap: () => context.push('/notifications'),
                      ),
                      _QuickAction(
                        icon: Icons.person_rounded,
                        label: t.profile,
                        onTap: () => context.go('/profile'),
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
  });

  final String title;
  final String welcome;
  final String balanceLabel;
  final String subtitle;
  final String villaName;
  final String villaNumber;
  final double balance;
  final bool isCredit;

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
            villaNumber.isEmpty ? title : '$title - $villaNumber',
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
            '${balance.abs().toStringAsFixed(0)} EGP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
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
