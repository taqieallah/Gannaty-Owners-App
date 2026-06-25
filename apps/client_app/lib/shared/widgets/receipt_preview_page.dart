import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  late final Future<_PreviewData> _future = _load();

  Future<_PreviewData> _load() async {
    final source = widget.source.trim();
    if (source.isEmpty) {
      throw Exception('لا يوجد رابط صالح للإيصال');
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return _downloadFromUrl(source);
    }

    try {
      final storage = FirebaseStorage.instanceFor(app: Firebase.app('expenses'));
      final bytes = await storage.ref(source).getData(25 * 1024 * 1024);
      if (bytes != null && bytes.isNotEmpty) {
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
        appBar: AppBar(title: Text(widget.title)),
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
                allowPrinting: false,
                allowSharing: true,
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
