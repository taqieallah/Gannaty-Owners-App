import 'dart:io';
import 'dart:typed_data';

import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPreviewPage extends StatefulWidget {
  const ReceiptPreviewPage({
    super.key,
    required this.source,
    this.title = 'الإيصال',
  });

  final String source;
  final String title;

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  _PreviewData? _data;
  late final Future<_PreviewData> _future = _load()
    ..then((d) {
      if (mounted) setState(() => _data = d);
    }).ignore();

  Future<_PreviewData> _load() async {
    final source = widget.source.trim();
    if (source.isEmpty) {
      throw Exception('لا يوجد رابط صالح للإيصال');
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return _downloadFromUrl(source);
    }

    try {
      final bytes = await SupaStorage.downloadBytes(source);
      if (bytes.isNotEmpty) {
        return _PreviewData(bytes: bytes, name: source);
      }
    } catch (_) {}

    throw Exception('تعذر تحميل الإيصال');
  }

  Future<_PreviewData> _downloadFromUrl(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        throw Exception('فشل تحميل الإيصال (${res.statusCode})');
      }
      final chunks = <int>[];
      await for (final c in res) {
        chunks.addAll(c);
      }
      return _PreviewData(bytes: Uint8List.fromList(chunks), name: url);
    } finally {
      client.close(force: true);
    }
  }

  /// Hands the receipt to the OS share sheet. Image receipts are wrapped in a
  /// single-page PDF first so every receipt shares through the same path.
  Future<void> _share(_PreviewData d) async {
    final bytes = _isPdf(d) ? d.bytes : await _imageToPdf(d.bytes);
    await Printing.sharePdf(bytes: bytes, filename: 'receipt.pdf');
  }

  Future<Uint8List> _imageToPdf(Uint8List image) async {
    final doc = pw.Document();
    final page = pw.MemoryImage(image);
    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Image(page, fit: pw.BoxFit.contain),
        ),
      ),
    );
    return doc.save();
  }

  bool _isPdf(_PreviewData d) {
    final name = d.name.toLowerCase();
    if (name.endsWith('.pdf')) return true;
    final b = d.bytes;
    return b.length >= 4 &&
        b[0] == 0x25 &&
        b[1] == 0x50 &&
        b[2] == 0x44 &&
        b[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            if (_data != null)
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'مشاركة الإيصال',
                onPressed: () => _share(_data!),
              ),
          ],
        ),
        body: FutureBuilder<_PreviewData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('خطأ: ${snap.error}'));
            }
            final data = snap.data!;
            if (_isPdf(data)) {
              return PdfPreview(
                useActions: false, // hide the internal print/toolbar
                canChangeOrientation: false,
                canChangePageFormat: false,
                build: (_) async => data.bytes,
              );
            }
            return Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Image.memory(data.bytes),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewData {
  const _PreviewData({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}
