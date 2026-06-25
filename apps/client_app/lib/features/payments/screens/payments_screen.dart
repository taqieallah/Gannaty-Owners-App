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

// ── Filter state ────────────────────────────────────────────────────────────

enum _TxFilter { all, payments, charges }

class _FilterState {
  const _FilterState({this.year, this.filter = _TxFilter.all});
  final int? year;
  final _TxFilter filter;

  _FilterState copyWith({int? Function()? year, _TxFilter? filter}) =>
      _FilterState(
        year: year != null ? year() : this.year,
        filter: filter ?? this.filter,
      );
}

class _FilterNotifier extends Notifier<_FilterState> {
  @override
  _FilterState build() => const _FilterState();
  void update(_FilterState Function(_FilterState) fn) => state = fn(state);
}

final _filterProvider =
    NotifierProvider<_FilterNotifier, _FilterState>(_FilterNotifier.new);

// ── Screen ──────────────────────────────────────────────────────────────────

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final accountAsync = ref.watch(ownerAccountProvider);
    final txAsync = ref.watch(ownerTransactionsStreamProvider);
    final filterState = ref.watch(_filterProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    // Auto-refresh balance when stream updates.
    ref.listen(ownerTransactionsStreamProvider, (_, next) {
      if (next.hasValue) ref.invalidate(ownerAccountProvider);
    });

    return ClientPageScaffold(
      title: t.payments,
      body: ListView(
        children: [
          // ── Villa header ──────────────────────────────────────────────
          if (villa != null)
            _VillaHeader(villa: villa, title: t.gannatyCompound),
          const SizedBox(height: 16),

          // ── Balance summary card ──────────────────────────────────────
          accountAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (account) {
              if (account == null) return const SizedBox.shrink();
              return _OwnerSummaryCard(account: account);
            },
          ),
          const SizedBox(height: 16),

          // ── Transactions list ─────────────────────────────────────────
          txAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text('خطأ في التحميل: $e'),
              ),
            ),
            data: (entries) {
              final ownerName = villa?.ownerName ?? '';
              final villaNo = villa?.villaNumber ?? '';

              // Build year list for filter chips.
              final years = entries
                  .map((e) => _txYear(e.txDate))
                  .where((y) => y != null)
                  .cast<int>()
                  .toSet()
                  .toList()
                ..sort((a, b) => b.compareTo(a));

              // Apply filters.
              final filtered = entries.where((e) {
                if (filterState.year != null &&
                    _txYear(e.txDate) != filterState.year) {
                  return false;
                }
                return switch (filterState.filter) {
                  _TxFilter.payments => e.isPayment,
                  _TxFilter.charges => e.isCharge,
                  _TxFilter.all => true,
                };
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Filter chips ──────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: t.allYears,
                          selected: filterState.year == null,
                          onTap: () => ref
                              .read(_filterProvider.notifier)
                              .update((s) => s.copyWith(year: () => null)),
                        ),
                        ...years.map(
                          (y) => _FilterChip(
                            label: '$y',
                            selected: filterState.year == y,
                            onTap: () => ref
                                .read(_filterProvider.notifier)
                                .update((s) => s.copyWith(year: () => y)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'المسدد',
                          selected: filterState.filter == _TxFilter.payments,
                          color: AppTheme.success,
                          onTap: () => ref
                              .read(_filterProvider.notifier)
                              .update((s) => s.copyWith(
                                    filter: filterState.filter ==
                                            _TxFilter.payments
                                        ? _TxFilter.all
                                        : _TxFilter.payments,
                                  )),
                        ),
                        _FilterChip(
                          label: 'غير المسدد',
                          selected: filterState.filter == _TxFilter.charges,
                          color: AppTheme.danger,
                          onTap: () => ref
                              .read(_filterProvider.notifier)
                              .update((s) => s.copyWith(
                                    filter: filterState.filter ==
                                            _TxFilter.charges
                                        ? _TxFilter.all
                                        : _TxFilter.charges,
                                  )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── List or empty state ───────────────────────────────
                  if (filtered.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Center(
                          child: Text(
                            entries.isEmpty
                                ? t.noPaidPaymentsYet
                                : 'لا توجد نتائج للفلتر المحدد',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildGrouped(
                      context,
                      filtered,
                      ownerName: ownerName,
                      villaNo: villaNo,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int? _txYear(String txDate) {
    if (txDate.length >= 4) return int.tryParse(txDate.substring(0, 4));
    return null;
  }

  List<Widget> _buildGrouped(
    BuildContext context,
    List<OwnerLedgerEntry> entries, {
    required String ownerName,
    required String villaNo,
  }) {
    final grouped = <int, List<OwnerLedgerEntry>>{};
    for (final e in entries) {
      final y = _txYear(e.txDate) ?? 0;
      grouped.putIfAbsent(y, () => []).add(e);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return years.map((year) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _TxYearCard(
          year: year,
          entries: grouped[year]!,
          ownerName: ownerName,
          villaNo: villaNo,
        ),
      );
    }).toList();
  }
}

// ── Owner summary card ───────────────────────────────────────────────────────

class _OwnerSummaryCard extends StatelessWidget {
  const _OwnerSummaryCard({required this.account});
  final OwnerAccount account;

  @override
  Widget build(BuildContext context) {
    final isCredit = account.isCredit;
    final balanceColor = isCredit ? AppTheme.success : AppTheme.danger;
    final fmt = NumberFormat('#,##0.##');

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
                    'ملخص الحساب ${account.year}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: balanceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCredit ? 'دائن ✓' : 'مدين',
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'إجمالي الرسوم',
              value: '${fmt.format(account.totalCharges)} جنيه',
              color: AppTheme.danger,
            ),
            _SummaryRow(
              label: 'إجمالي المدفوعات',
              value: '${fmt.format(account.totalPayments)} جنيه',
              color: AppTheme.success,
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: balanceColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: balanceColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الرصيد الحالي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${fmt.format(account.balance.abs())} جنيه',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.w800,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsetsDirectional.only(end: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Transactions grouped by year ─────────────────────────────────────────────

class _TxYearCard extends StatelessWidget {
  const _TxYearCard({
    required this.year,
    required this.entries,
    required this.ownerName,
    required this.villaNo,
  });

  final int year;
  final List<OwnerLedgerEntry> entries;
  final String ownerName;
  final String villaNo;

  @override
  Widget build(BuildContext context) {
    double totalPaid = 0;
    double totalCharged = 0;
    for (final e in entries) {
      if (e.isPayment) {
        totalPaid += e.amount;
      } else {
        totalCharged += e.amount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year header with totals
            Row(
              children: [
                Expanded(
                  child: Text(
                    'حركات $year',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (totalCharged > 0)
                      Text(
                        '${NumberFormat('#,##0').format(totalCharged)} رسوم',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (totalPaid > 0)
                      Text(
                        '${NumberFormat('#,##0').format(totalPaid)} مدفوع',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TxTile(
                  entry: e,
                  ownerName: ownerName,
                  villaNo: villaNo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single transaction tile ──────────────────────────────────────────────────

class _TxTile extends StatelessWidget {
  const _TxTile({
    required this.entry,
    required this.ownerName,
    required this.villaNo,
  });

  final OwnerLedgerEntry entry;
  final String ownerName;
  final String villaNo;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppTheme.success : AppTheme.cognac;
    final fmt = NumberFormat('#,##0.##');
    final amountStr = fmt.format(entry.amount);

    String dateStr = entry.txDate;
    try {
      dateStr =
          DateFormat('d MMM yyyy', 'ar').format(DateTime.parse(entry.txDate));
    } catch (_) {}

    final label = entry.category?.isNotEmpty == true
        ? entry.category!
        : (isPayment ? 'دفعة' : 'رسوم');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => OwnerReceiptSheet.show(
        context,
        entry: entry,
        ownerName: ownerName,
        villaNo: villaNo,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPayment
                    ? Icons.check_circle_rounded
                    : Icons.receipt_long_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // ── Details ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if ((entry.description ?? '').isNotEmpty)
                    Text(
                      entry.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            // ── Amount ────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountStr جنيه',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.receipt_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 3),
                    Text(
                      'عرض الإيصال',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? activeColor
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? activeColor
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _VillaHeader extends StatelessWidget {
  const _VillaHeader({required this.villa, required this.title});

  final Villa villa;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C2D1A), AppTheme.cognac],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title - ${villa.villaNumber}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${villa.ownerName} - ${villa.phoneNumber}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
