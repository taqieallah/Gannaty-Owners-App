import 'dart:io';
import 'package:compound_core/compound_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';

class ImportExcelScreen extends ConsumerStatefulWidget {
  const ImportExcelScreen({super.key});
  @override
  ConsumerState<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends ConsumerState<ImportExcelScreen> {
  ExcelParseResult? _result;
  String? _fileName;
  bool _importing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    List<int> bytes;

    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      return;
    }

    final parsed = ExcelParser.parse(bytes, '');
    setState(() {
      _result = parsed;
      _fileName = file.name;
    });
  }

  Future<void> _import() async {
    if (_result == null || _result!.payments.isEmpty) return;
    setState(() => _importing = true);

    try {
      await ref
          .read(paymentRepositoryProvider)
          .batchAdd(_result!.payments);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_result!.payments.length} payments imported successfully')),
        );
        context.go('/payments');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Excel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Required Excel Columns',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      'VillaNumber | Month | Year | Amount | DueDate | IsPaid (optional) | Description (optional)',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text('DueDate format: dd/mm/yyyy or yyyy-mm-dd',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File picker button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName ?? 'Choose Excel File (.xlsx)'),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.check, color: Colors.white, size: 16),
                    label: Text('${_result!.payments.length} valid rows'),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  if (_result!.hasErrors)
                    Chip(
                      avatar: const Icon(Icons.warning, color: Colors.white, size: 16),
                      label: Text('${_result!.errors.length} errors'),
                      backgroundColor: Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                ],
              ),

              // Error list
              if (_result!.hasErrors) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.red.shade50,
                  child: ExpansionTile(
                    title: Text('${_result!.errors.length} rows with errors (will be skipped)'),
                    children: _result!.errors
                        .map((e) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              title: Text(e,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ),
              ],

              // Preview table
              if (_result!.payments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Preview (first 5 rows)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    columns: const [
                      DataColumn(label: Text('Villa')),
                      DataColumn(label: Text('Month')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Due Date')),
                      DataColumn(label: Text('Paid')),
                    ],
                    rows: _result!.payments
                        .take(5)
                        .map((p) => DataRow(cells: [
                              DataCell(Text(p.villaNumber)),
                              DataCell(Text(p.monthLabel)),
                              DataCell(Text(fmt.format(p.amount))),
                              DataCell(Text(
                                  '${p.dueDate.day}/${p.dueDate.month}/${p.dueDate.year}')),
                              DataCell(Icon(
                                p.isPaid ? Icons.check : Icons.close,
                                size: 16,
                                color: p.isPaid
                                    ? Colors.green
                                    : Colors.grey,
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ],

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _importing || _result!.payments.isEmpty
                      ? null
                      : _import,
                  icon: _importing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload),
                  label: Text(_importing
                      ? 'Importing...'
                      : 'Import ${_result!.payments.length} Payments'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
