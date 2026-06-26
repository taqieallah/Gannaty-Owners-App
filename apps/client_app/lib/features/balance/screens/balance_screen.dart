import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';
import '../../../shared/widgets/owner_receipt_sheet.dart';

class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    // Use the real-time stream so the list updates without a restart.
    final txAsync = ref.watch(ownerTransactionsStreamProvider);

    // Whenever the transaction stream emits new data, re-fetch the balance.
    ref.listen(ownerTransactionsStreamProvider, (prev, next) {
      if (next.hasValue) ref.invalidate(ownerAccountProvider);
    });
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.ownerAccountTitle,
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (account) {
          if (account == null) return _NotSetupState(t: t);

          final isCredit = account.isCredit;
          final balanceAbs = account.balance.abs();

          return ListView(
            children: [
              // ── Year selector ───────────────────────────────────────────
              ref.watch(ownerStatementYearsProvider).maybeWhen(
                    data: (years) {
                      final sel = ref.watch(selectedOwnerYearProvider);
                      final items = years.contains(sel)
                          ? years
                          : [sel, ...years]
                        ..sort((a, b) => b.compareTo(a));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 10),
                              Text('${t.forYear}:',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
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
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

              // ── Hero balance card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCredit
                        ? [const Color(0xFF1A5C2D), AppTheme.success]
                        : [const Color(0xFF5C2D1A), AppTheme.cognac],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCredit
                              ? Icons.check_circle_rounded
                              : Icons.account_balance_wallet_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          villa != null
                              ? '${t.ownerAccountTitle} - ${t.forYear} ${account.year}'
                              : t.ownerAccountTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${balanceAbs.toStringAsFixed(0)} EGP',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCredit ? t.creditBalance : t.debitBalance,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Two summary chips ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: t.totalChargesLabel,
                      value:
                          '${(account.totalCharges + account.maintenance).toStringAsFixed(0)} EGP',
                      color: AppTheme.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: t.totalPaymentsLabel,
                      value: '${account.totalPayments.toStringAsFixed(0)} EGP',
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Account breakdown card ──────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.balanceSummary,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      _Row(label: t.maintenanceFee,
                          value: '${account.maintenance.toStringAsFixed(0)} EGP'),
                      if (account.openingBalance != 0)
                        _Row(
                          label: t.openingBalance,
                          value:
                              '${account.openingBalance.toStringAsFixed(0)} EGP',
                        ),
                      if (account.depositReturn > 0)
                        _Row(
                          label: t.depositReturn,
                          value:
                              '− ${account.depositReturn.toStringAsFixed(0)} EGP',
                          color: AppTheme.success,
                        ),
                      if (account.totalCharges > 0)
                        _Row(
                          label: t.totalChargesLabel,
                          value:
                              '+ ${account.totalCharges.toStringAsFixed(0)} EGP',
                          color: AppTheme.danger,
                        ),
                      _Row(
                        label: t.totalPaymentsLabel,
                        value:
                            '− ${account.totalPayments.toStringAsFixed(0)} EGP',
                        color: AppTheme.success,
                      ),
                      const Divider(height: 20),
                      _Row(
                        label: isCredit ? t.creditBalance : t.debitBalance,
                        value:
                            '${account.balance.toStringAsFixed(0)} EGP',
                        highlight: true,
                        color: isCredit ? AppTheme.success : AppTheme.danger,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Detailed account statement (matches the ERP Excel/PDF) ──
              if (account.statement != null &&
                  account.statement!.rows.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.accountStatement} ${account.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final r in account.statement!.rows)
                          _StatementRowView(row: r),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Year settings details ───────────────────────────────────
              if (account.meterPrice > 0) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.accountStatement} ${account.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        _Row(
                          label: t.area,
                          value:
                              '${account.villaArea.toStringAsFixed(0)} م²',
                        ),
                        _Row(
                          label: t.pricePerMeterLabel,
                          value:
                              '${account.meterPrice.toStringAsFixed(0)} EGP/م²',
                        ),
                        if (account.depositPaid > 0) ...[
                          _Row(
                            label: t.deposit,
                            value:
                                '${account.depositPaid.toStringAsFixed(0)} EGP',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Ledger history ──────────────────────────────────────────
              txAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (entries) => _LedgerList(
                      entries: entries,
                      t: t,
                      ownerName: account.name,
                      villaNo: account.villaNo,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Not setup state ────────────────────────────────────────────────────────

class _NotSetupState extends StatelessWidget {
  const _NotSetupState({required this.t});
  final AppText t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(t.ownerNotSetup,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(t.ownerNotSetupHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}

// ── Ledger list ────────────────────────────────────────────────────────────

class _LedgerList extends StatelessWidget {
  const _LedgerList({
    required this.entries,
    required this.t,
    required this.ownerName,
    required this.villaNo,
  });

  final List<OwnerLedgerEntry> entries;
  final AppText t;
  final String ownerName;
  final String villaNo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.ledgerHistory,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(t.noLedgerEntries,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ),
              )
            else
              ...entries.map((e) => _LedgerRow(
                    entry: e,
                    t: t,
                    ownerName: ownerName,
                    villaNo: villaNo,
                  )),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.t,
    required this.ownerName,
    required this.villaNo,
  });

  final OwnerLedgerEntry entry;
  final AppText t;
  final String ownerName;
  final String villaNo;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppTheme.success : AppTheme.danger;
    final sign = isPayment ? '−' : '+';
    final label = entry.category?.isNotEmpty == true
        ? entry.category!
        : (isPayment ? t.totalPaymentsLabel : t.charge);

    String formattedDate;
    try {
      final dt = DateTime.parse(entry.txDate);
      formattedDate = DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      formattedDate = entry.txDate;
    }

    return InkWell(
      onTap: () => OwnerReceiptSheet.show(
        context,
        entry: entry,
        ownerName: ownerName,
        villaNo: villaNo,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPayment
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (entry.description?.isNotEmpty == true)
                  Text(entry.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                Text(formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          Text(
            '$sign ${entry.amount.toStringAsFixed(0)} EGP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_left_rounded,
              size: 18, color: Colors.grey.shade400),
        ],
      ),
    ));
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (highlight
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        highlight ? FontWeight.w800 : FontWeight.normal,
                    color: effectiveColor,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: effectiveColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// Renders one detailed statement row (label / details / amount) exactly like
/// the ERP's Excel/PDF account breakdown.
class _StatementRowView extends StatelessWidget {
  const _StatementRowView({required this.row});

  final OwnerStatementRow row;

  static String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final out = '$buf.${parts[1]}';
    return neg ? '($out)' : out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (row.kind == 'section') {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(
          row.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
        ),
      );
    }

    final isResult = row.kind == 'result';
    final amount = row.amount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            (row.bold || isResult) ? FontWeight.w800 : null,
                      ),
                ),
                if (row.details.isNotEmpty)
                  Text(
                    row.details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount == null ? '—' : '${_money(amount)} EGP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      (row.bold || isResult) ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
