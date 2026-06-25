import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'receipt_preview_page.dart';

class OwnerReceiptSheet extends ConsumerStatefulWidget {
  const OwnerReceiptSheet({
    super.key,
    required this.entry,
    required this.ownerName,
    required this.villaNo,
  });

  final OwnerLedgerEntry entry;
  final String ownerName;
  final String villaNo;

  static Future<void> show(
    BuildContext context, {
    required OwnerLedgerEntry entry,
    required String ownerName,
    required String villaNo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OwnerReceiptSheet(
        entry: entry,
        ownerName: ownerName,
        villaNo: villaNo,
      ),
    );
  }

  @override
  ConsumerState<OwnerReceiptSheet> createState() => _OwnerReceiptSheetState();
}

class _OwnerReceiptSheetState extends ConsumerState<OwnerReceiptSheet> {
  bool _attachmentLoading = false;
  String? _attachmentUrl;
  String? _errorMsg;

  Future<void> _openAttachment() async {
    if (_attachmentLoading) return;

    if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty) {
      await _showPreview(_attachmentUrl!);
      return;
    }

    setState(() {
      _attachmentLoading = true;
      _errorMsg = null;
    });

    try {
      String? url = (widget.entry.receiptUrl ?? '').trim();
      if (url.isEmpty) url = null;

      if (url == null) {
        final repo = ref.read(ownerAccountRepositoryProvider);
        final result = await repo.fetchTxAttachmentUrlDebug(
          widget.entry.id,
          txNotes: widget.entry.notes,
          txRefNo: widget.entry.refNo,
          txDate: widget.entry.txDate,
          txAmount: widget.entry.amount,
          txDescription: widget.entry.description,
        );
        url = result.$1;
        final debugInfo = result.$2;

        if (!mounted) return;
        if (url == null || url.isEmpty) {
          setState(() {
            _attachmentUrl = '';
            _errorMsg = debugInfo.isNotEmpty
                ? debugInfo
                : 'لا يوجد إيصال مرفق لهذه الحركة';
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() => _attachmentUrl = url);
      await _showPreview(url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'خطأ في تحميل الإيصال: $e');
    } finally {
      if (mounted) {
        setState(() => _attachmentLoading = false);
      }
    }
  }

  Future<void> _showPreview(String source) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPreviewPage(source: source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isPayment = entry.isPayment;
    final color = isPayment ? AppTheme.success : AppTheme.cognac;
    final dateStr = _formatDate(entry.txDate);
    final amountStr = NumberFormat('#,##0.##').format(entry.amount);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPayment
                        ? Icons.check_circle_rounded
                        : Icons.receipt_long_rounded,
                    color: color,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  isPayment ? 'إيصال دفع' : 'إشعار رسوم',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      'المبلغ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$amountStr جنيه',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _ReceiptDivider(label: 'تفاصيل الإيصال'),
              _ReceiptRow(label: 'اسم المالك', value: widget.ownerName),
              _ReceiptRow(label: 'رقم الوحدة', value: widget.villaNo),
              if ((entry.category ?? '').isNotEmpty)
                _ReceiptRow(label: 'التصنيف', value: entry.category!),
              if ((entry.description ?? '').isNotEmpty)
                _ReceiptRow(label: 'البيان', value: entry.description!),
              _ReceiptRow(
                label: 'النوع',
                value: isPayment ? 'دفعة' : 'رسوم',
                valueColor: color,
              ),
              _ReceiptRow(label: 'التاريخ', value: dateStr),
              if ((entry.refNo ?? 0) > 0)
                _ReceiptRow(label: 'رقم الإيصال', value: entry.refNo.toString()),
              const SizedBox(height: 20),
              _ViewReceiptButton(
                loading: _attachmentLoading,
                onTap: _openAttachment,
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (_attachmentUrl?.isEmpty ?? false)
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_attachmentUrl?.isEmpty ?? false)
                          ? Colors.orange.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        (_attachmentUrl?.isEmpty ?? false)
                            ? Icons.info_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: (_attachmentUrl?.isEmpty ?? false)
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            fontSize: 13,
                            color: (_attachmentUrl?.isEmpty ?? false)
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'كمبوند جنتي - نظام إدارة الملاك',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'ar').format(d);
    } catch (_) {
      return isoDate;
    }
  }
}

class _ViewReceiptButton extends StatelessWidget {
  const _ViewReceiptButton({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cognac,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.cognac.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_rounded, size: 22),
        label: Text(
          loading ? 'جارٍ تحميل الإيصال...' : 'عرض إيصال الدفع',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

