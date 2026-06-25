import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/ds_components.dart';

enum _Filter { all, unpaid, overdue, paid }

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});
  @override
  ConsumerState<PaymentsListScreen> createState() =>
      _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  _Filter _filter = _Filter.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = context.appColors;
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return AppScaffold(
      title: l10n.paymentsTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_rounded),
          tooltip: l10n.isAr ? 'استيراد من Excel' : 'Import Excel',
          onPressed: () => context.go('/payments/import'),
        ),
      ],
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 12, AppSpacing.screenH, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.isAr
                    ? '...بحث برقم الفيلا'
                    : 'Search villa number...',
                prefixIcon:
                    Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
              ),
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH, vertical: 12),
            child: Row(
              children: _Filter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f, l10n)),
                    selected: selected,
                    selectedColor: AppColors.navyLight,
                    checkmarkColor: AppColors.navy,
                    onSelected: (_) =>
                        setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          // Payment list
          Expanded(
            child: paymentsAsync.when(
              data: (payments) {
                var filtered = payments.where((p) {
                  switch (_filter) {
                    case _Filter.unpaid:
                      return !p.isPaid;
                    case _Filter.overdue:
                      return p.isOverdue;
                    case _Filter.paid:
                      return p.isPaid;
                    case _Filter.all:
                      return true;
                  }
                }).where((p) {
                  if (_search.isEmpty) return true;
                  return p.villaNumber
                      .toLowerCase()
                      .contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return GdsEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.isAr
                        ? 'لا توجد مدفوعات'
                        : 'No payments found',
                    subtitle: l10n.isAr
                        ? 'جرّب تغيير الفلتر أو البحث'
                        : 'Try changing the filter or search',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, 0, AppSpacing.screenH, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PaymentCard(
                      payment: filtered[i],
                      l10n: l10n,
                    ),
                  ),
                );
              },
              loading: () => const GdsLoading(),
              error: (e, _) => Center(
                child: Text('${l10n.error}: $e',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/payments/add'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPayment),
      ),
    );
  }

  String _filterLabel(_Filter f, AppL10n l10n) {
    switch (f) {
      case _Filter.all:
        return l10n.all;
      case _Filter.unpaid:
        return l10n.isAr ? 'غير مدفوع' : 'Unpaid';
      case _Filter.overdue:
        return l10n.overdue;
      case _Filter.paid:
        return l10n.paid;
    }
  }
}

// == Payment Card =============================================================

class _PaymentCard extends ConsumerWidget {
  final Payment payment;
  final AppL10n l10n;
  const _PaymentCard({required this.payment, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0.00');
    final colors = context.appColors;

    final Color iconColor;
    final Color iconBg;
    final IconData iconData;
    final GdsChipVariant chipVariant;
    final String chipLabel;

    if (payment.isPaid) {
      iconColor = AppColors.success;
      iconBg = AppColors.successLight;
      iconData = Icons.check_circle_outline_rounded;
      chipVariant = GdsChipVariant.paid;
      chipLabel = l10n.paid;
    } else if (payment.isOverdue) {
      iconColor = AppColors.error;
      iconBg = AppColors.errorLight;
      iconData = Icons.warning_amber_rounded;
      chipVariant = GdsChipVariant.overdue;
      chipLabel = l10n.overdue;
    } else {
      iconColor = AppColors.warning;
      iconBg = AppColors.warningLight;
      iconData = Icons.schedule_rounded;
      chipVariant = GdsChipVariant.pending;
      chipLabel = l10n.pending;
    }

    final hasAttachments = payment.attachments.isNotEmpty;

    return GdsCard(
      highlighted: payment.isOverdue && !payment.isPaid,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.villaNum(payment.villaNumber),
                        style: AppTextStyles.titleSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        payment.monthLabel,
                        style: AppTextStyles.caption
                            .copyWith(color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${l10n.dueDatePrefix} ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
                      style: AppTextStyles.caption.copyWith(
                          color: payment.isOverdue && !payment.isPaid
                              ? AppColors.error
                              : colors.textHint),
                    ),
                    if (hasAttachments) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.attach_file_rounded,
                          size: 13, color: colors.textHint),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount + status + toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fmt.format(payment.amount),
                  style: AppTextStyles.number.copyWith(
                      color: colors.textPrimary, fontSize: 15)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GdsStatusChip(
                      variant: chipVariant, label: chipLabel),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    child: FittedBox(
                      child: Switch.adaptive(
                        value: payment.isPaid,
                        activeColor: AppColors.success,
                        onChanged: (val) async {
                          await ref
                              .read(paymentRepositoryProvider)
                              .markPaid(payment.id, val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
