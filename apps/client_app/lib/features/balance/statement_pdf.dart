import 'dart:typed_data';

import 'package:compound_core/compound_core.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds and shares a clean, RTL Arabic account-statement PDF for the owner's
/// selected year — header, financial summary and the year's transactions.
Future<void> shareStatementPdf({
  required OwnerAccount account,
  required List<OwnerLedgerEntry> transactions,
}) async {
  final bytes = await _build(account, transactions);
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'كشف_حساب_${account.villaNo}_${account.year}.pdf',
  );
}

final _money = NumberFormat('#,##0.##', 'en');
String _m(num v) => _money.format(v);

String _date(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : '${d.day}/${d.month}/${d.year}';
}

const _navy = PdfColor.fromInt(0xFF3A2416);
const _copper = PdfColor.fromInt(0xFF7A4726);
const _green = PdfColor.fromInt(0xFF168267);
const _red = PdfColor.fromInt(0xFFC64040);
const _line = PdfColor.fromInt(0xFFE4DBCE);
const _soft = PdfColor.fromInt(0xFF8A6B55);
const _fill = PdfColor.fromInt(0xFFF7F1E3);

Future<Uint8List> _build(
    OwnerAccount account, List<OwnerLedgerEntry> transactions) async {
  final regular = await PdfGoogleFonts.cairoRegular();
  final bold = await PdfGoogleFonts.cairoBold();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final year = account.year;
  final entries = transactions
      .where((e) => e.txDate.startsWith('$year'))
      .toList()
    ..sort((a, b) => a.txDate.compareTo(b.txDate));

  final isCredit = account.isCredit;
  final statusText = isCredit
      ? 'رصيد لصالح المالك'
      : (account.balance.abs() < 0.01 ? 'الحساب مسدّد' : 'عليه مديونية');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      textDirection: pw.TextDirection.rtl,
      header: (ctx) => ctx.pageNumber == 1 ? _header(account) : pw.SizedBox(),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'اتحاد شاغلي كمبوند جنتي  •  صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _soft),
        ),
      ),
      build: (ctx) => [
        pw.SizedBox(height: 14),
        _summary(account, statusText, isCredit),
        pw.SizedBox(height: 18),
        pw.Text('حركات سنة $year',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (entries.isEmpty)
          pw.Text('لا توجد حركات مسجّلة لهذه السنة.',
              style: const pw.TextStyle(color: _soft, fontSize: 10))
        else
          _table(entries),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _header(OwnerAccount account) {
  return pw.Column(children: [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('كشف حساب المالك',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 2),
          pw.Text('اتحاد شاغلي كمبوند جنتي',
              style: const pw.TextStyle(fontSize: 10, color: _soft)),
        ]),
        pw.Container(
          width: 46,
          height: 46,
          decoration: pw.BoxDecoration(
              color: _copper,
              borderRadius: pw.BorderRadius.circular(10)),
          alignment: pw.Alignment.center,
          child: pw.Text('جنتي',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    ),
    pw.SizedBox(height: 12),
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
          color: _fill, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _kv('المالك', account.name),
          _kv('الوحدة', 'فيلا ${account.villaNo}'),
          _kv('السنة', '${account.year}'),
          _kv('تاريخ الإصدار',
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
        ],
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Divider(color: _line, thickness: 1),
  ]);
}

pw.Widget _kv(String k, String v) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(k, style: const pw.TextStyle(fontSize: 8, color: _soft)),
        pw.SizedBox(height: 2),
        pw.Text(v, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
      ],
    );

pw.Widget _summary(OwnerAccount a, String status, bool isCredit) {
  final balColor = isCredit || a.balance.abs() < 0.01 ? _green : _red;
  return pw.Column(children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
          color: _navy, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('الرصيد الحالي',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text('${_m(a.balance.abs())} جنيه',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(20)),
            child: pw.Text(status,
                style: pw.TextStyle(
                    color: balColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    ),
    pw.SizedBox(height: 10),
    pw.Row(children: [
      _stat('الرصيد الافتتاحي', '${_m(a.openingBalance)} جنيه'),
      pw.SizedBox(width: 8),
      _stat('إجمالي الرسوم', '${_m(a.totalCharges + a.maintenance)} جنيه'),
      pw.SizedBox(width: 8),
      _stat('إجمالي المدفوعات', '${_m(a.totalPayments)} جنيه', color: _green),
    ]),
  ]);
}

pw.Widget _stat(String label, String value, {PdfColor? color}) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line),
            borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: _soft)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color ?? _navy)),
        ]),
      ),
    );

pw.Widget _table(List<OwnerLedgerEntry> entries) {
  pw.Widget cell(String s,
          {bool head = false, PdfColor? color, pw.Alignment? align}) =>
      pw.Container(
        alignment: align ?? pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Text(s,
            style: pw.TextStyle(
                fontSize: 9.5,
                color: color ?? (head ? PdfColors.white : _navy),
                fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: _copper),
      children: [
        cell('التاريخ', head: true),
        cell('البيان', head: true),
        cell('النوع', head: true),
        cell('المبلغ', head: true, align: pw.Alignment.centerLeft),
      ],
    ),
  ];
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final pay = e.isPayment;
    final label = (e.category?.isNotEmpty == true)
        ? e.category!
        : (pay ? 'دفعة' : 'رسوم');
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(
          color: i.isEven ? PdfColors.white : _fill),
      children: [
        cell(_date(e.txDate)),
        cell(label),
        cell(pay ? 'إيداع' : 'خصم', color: pay ? _green : _red),
        cell('${pay ? '+' : '−'}${_m(e.amount)}',
            color: pay ? _green : _red, align: pw.Alignment.centerLeft),
      ],
    ));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: _line, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(4),
      2: pw.FlexColumnWidth(1.6),
      3: pw.FlexColumnWidth(2.2),
    },
    children: rows,
  );
}
