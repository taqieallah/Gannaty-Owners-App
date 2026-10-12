import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';
import '../../../shared/widgets/skeleton.dart';

final _repoProvider = Provider<VisitorPassRepository>(
  (ref) => VisitorPassRepository(),
);

final visitorPassesProvider = FutureProvider.autoDispose<List<VisitorPass>>(
  (ref) => ref.watch(_repoProvider).list(),
);

final _dateFmt = DateFormat('dd/MM  HH:mm');

class VisitorsScreen extends ConsumerWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passes = ref.watch(visitorPassesProvider);
    return ClientPageScaffold(
      title: 'دعوة زائر',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text('دعوة زائر'),
      ),
      body: passes.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(
          child: Text('تعذّر تحميل التصاريح، حاول لاحقًا',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(visitorPassesProvider),
          child: items.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  Icon(Icons.qr_code_2_rounded, size: 64, color: AppTheme.cognac),
                  SizedBox(height: 12),
                  Text('لا توجد دعوات بعد.\nاضغط "دعوة زائر" لإنشاء QR يفتح له البوابة.',
                      textAlign: TextAlign.center),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PassTile(
                    pass: items[i],
                    onTap: () => _show(context, ref, items[i]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final pass = await showModalBottomSheet<VisitorPass>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateSheet(),
    );
    if (pass == null || !context.mounted) return;
    ref.invalidate(visitorPassesProvider);
    await _show(context, ref, pass);
  }

  Future<void> _show(BuildContext context, WidgetRef ref, VisitorPass pass) {
    return showDialog<void>(
      context: context,
      builder: (_) => _QrDialog(
        pass: pass,
        onRevoked: () => ref.invalidate(visitorPassesProvider),
      ),
    );
  }
}

class _PassTile extends StatelessWidget {
  const _PassTile({required this.pass, required this.onTap});
  final VisitorPass pass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _state(pass);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.qr_code_2_rounded, color: color, size: 34),
        title: Text(pass.visitorName,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          'حتى ${_dateFmt.format(pass.validUntil)}  •  دخول ${pass.uses}/${pass.maxUses}',
        ),
        trailing: Chip(
          label: Text(label, style: TextStyle(color: color, fontSize: 12)),
          backgroundColor: color.withValues(alpha: 0.12),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

(String, Color) _state(VisitorPass p) {
  if (p.status == 'revoked') return ('ملغي', AppTheme.danger);
  if (p.uses >= p.maxUses || p.status == 'used') {
    return ('استُخدم', AppTheme.textSoft);
  }
  if (p.isExpired) return ('منتهي', AppTheme.textSoft);
  return ('ساري', AppTheme.success);
}

class _CreateSheet extends ConsumerStatefulWidget {
  const _CreateSheet();

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  int _hours = 24;
  int _uses = 1;
  bool _busy = false;
  String? _error;

  static const _durations = {
    '3 ساعات': 3,
    'يوم': 24,
    '3 أيام': 72,
    'أسبوع': 168,
  };
  static const _useOptions = {'مرة واحدة': 1, 'مرتين': 2, '5 مرات': 5, '10': 10};

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'اكتب اسم الزائر');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pass = await ref.read(_repoProvider).create(
            name: _name.text.trim(),
            hours: _hours,
            maxUses: _uses,
            note: _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, pass);
    } catch (e) {
      final s = e.toString();
      setState(() {
        _busy = false;
        _error = s.contains('too_many_active')
            ? 'عندك 20 دعوة سارية، ألغِ بعضها أولًا'
            : 'تعذّر إنشاء الدعوة، حاول مجددًا';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget chips(Map<String, int> options, int value, void Function(int) set) =>
        Wrap(
          spacing: 8,
          children: [
            for (final e in options.entries)
              ChoiceChip(
                label: Text(e.key),
                selected: value == e.value,
                onSelected: (_) => setState(() => set(e.value)),
              ),
          ],
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('دعوة زائر',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'اسم الزائر'),
            ),
            const SizedBox(height: 14),
            const Text('مدة الصلاحية'),
            const SizedBox(height: 6),
            chips(_durations, _hours, (v) => _hours = v),
            const SizedBox(height: 14),
            const Text('عدد مرات الدخول'),
            const SizedBox(height: 6),
            chips(_useOptions, _uses, (v) => _uses = v),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              decoration:
                  const InputDecoration(labelText: 'ملاحظة (اختياري) مثل رقم العربية'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'جاري الإنشاء...' : 'إنشاء QR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrDialog extends ConsumerStatefulWidget {
  const _QrDialog({required this.pass, required this.onRevoked});
  final VisitorPass pass;
  final VoidCallback onRevoked;

  @override
  ConsumerState<_QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends ConsumerState<_QrDialog> {
  bool _busy = false;

  Future<void> _share() async {
    final p = widget.pass;
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final doc = pw.Document();
    doc.addPage(pw.Page(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      textDirection: pw.TextDirection.rtl,
      build: (_) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('تصريح دخول - كمبوند جنّتي',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('الزائر: ${p.visitorName}',
                style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 18),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: p.qrData,
              width: 260,
              height: 260,
            ),
            pw.SizedBox(height: 10),
            pw.Text(p.code,
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('صالح حتى ${_dateFmt.format(p.validUntil)}  •  ${p.maxUses} مرة دخول'),
            pw.SizedBox(height: 6),
            pw.Text('اعرض هذا الرمز على أمن البوابة'),
          ],
        ),
      ),
    ));
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'visitor_${p.code}.pdf',
    );
  }

  Future<void> _revoke() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إلغاء الدعوة؟'),
        content: const Text('لن يتمكن الزائر من الدخول بهذا الرمز.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('إلغاء الدعوة')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(_repoProvider).revoke(widget.pass.code);
      widget.onRevoked();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر الإلغاء')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pass;
    final (label, color) = _state(p);
    return AlertDialog(
      title: Text(p.visitorName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              // Fixed box: QrImageView uses a LayoutBuilder, which an AlertDialog
              // cannot measure on its own (the dialog then fails to draw).
              child: SizedBox(
                width: 220,
                height: 220,
                child: QrImageView(data: p.qrData),
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(p.code,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('حتى ${_dateFmt.format(p.validUntil)}  •  دخول ${p.uses}/${p.maxUses}'),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      actions: [
        if (p.isUsable)
          TextButton(
            onPressed: _busy ? null : _revoke,
            child: const Text('إلغاء الدعوة',
                style: TextStyle(color: AppTheme.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('مشاركة'),
        ),
      ],
    );
  }
}
