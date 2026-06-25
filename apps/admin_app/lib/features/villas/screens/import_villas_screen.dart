import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:excel/excel.dart';
import 'package:compound_core/compound_core.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ImportVillasScreen extends ConsumerStatefulWidget {
  const ImportVillasScreen({super.key});
  @override
  ConsumerState<ImportVillasScreen> createState() => _ImportVillasScreenState();
}

class _ImportVillasScreenState extends ConsumerState<ImportVillasScreen> {
  bool _loading = false;
  String? _fileName;
  List<Villa> _preview = [];
  List<String> _errors = [];
  bool _imported = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _loading = true;
      _fileName = result.files.single.name;
      _preview = [];
      _errors = [];
    });

    try {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        setState(() { _errors = ['Empty spreadsheet']; _loading = false; });
        return;
      }

      final rows = sheet.rows;
      if (rows.isEmpty) {
        setState(() { _errors = ['No data found']; _loading = false; });
        return;
      }

      // Find headers (case-insensitive, flexible matching)
      final headerRow = rows.first;
      final headers = headerRow
          .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
          .toList();

      // Required columns
      final villaNumIdx = headers.indexWhere((h) =>
          h == 'villanumber' || h == 'villa number' || h == 'villa' || h == 'villa no');
      final ownerIdx = headers.indexWhere((h) =>
          h == 'ownername' || h == 'owner name' || h == 'owner');
      final phoneIdx = headers.indexWhere((h) =>
          h == 'phonenumber' || h == 'phone number' || h == 'phone');

      // Optional columns
      final areaIdx = headers.indexWhere((h) =>
          h == 'area' || h == 'villa area' || h == 'villaarea');
      final depositIdx = headers.indexWhere((h) =>
          h == 'deposit' || h == 'deposit amount' || h == 'depositamount');
      final passwordIdx = headers.indexWhere((h) =>
          h == 'password' || h == 'pass');
      final debt2024Idx = headers.indexWhere((h) =>
          h == '2024 dept' || h == '2024 debt' || h == 'debt2024' || h == 'dept2024' || h == '2024dept' || h == '2024debt');
      final debt2025Idx = headers.indexWhere((h) =>
          h == '2025 dept' || h == '2025 debt' || h == 'debt2025' || h == 'dept2025' || h == '2025dept' || h == '2025debt');
      final annualFeeIdx = headers.indexWhere((h) =>
          h == 'annual fee' || h == 'annualfee' || h == 'fee');

      if (villaNumIdx < 0 || ownerIdx < 0 || phoneIdx < 0) {
        setState(() {
          _errors = [
            'Missing required columns. Must have: VillaNumber (or Villa No), OwnerName (or Owner), PhoneNumber (or Phone)',
            'Found headers: ${headers.where((h) => h.isNotEmpty).join(", ")}',
          ];
          _loading = false;
        });
        return;
      }

      final villas = <Villa>[];
      final errors = <String>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        String cellStr(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          return row[idx]?.value?.toString().trim() ?? '';
        }

        double cellNum(int idx) {
          if (idx < 0 || idx >= row.length) return 0;
          final val = row[idx]?.value;
          if (val == null) return 0;
          if (val is IntCellValue) return val.value.toDouble();
          if (val is DoubleCellValue) return val.value;
          return double.tryParse(val.toString().trim()) ?? 0;
        }

        final villaNum = cellStr(villaNumIdx);
        final owner = cellStr(ownerIdx);
        final phone = cellStr(phoneIdx);

        if (villaNum.isEmpty && owner.isEmpty && phone.isEmpty) continue;
        if (villaNum.isEmpty) { errors.add('Row ${i + 1}: Missing VillaNumber'); continue; }
        if (owner.isEmpty) { errors.add('Row ${i + 1}: Missing OwnerName'); continue; }
        if (phone.isEmpty) { errors.add('Row ${i + 1}: Missing PhoneNumber'); continue; }

        final area = cellNum(areaIdx);
        final deposit = cellNum(depositIdx);
        final password = cellStr(passwordIdx);
        final debt2024 = cellNum(debt2024Idx);
        final debt2025 = cellNum(debt2025Idx);
        final annualFee = cellNum(annualFeeIdx);

        villas.add(Villa(
          id: '',
          villaNumber: villaNum,
          ownerName: owner,
          phoneNumber: phone,
          area: area,
          depositAmount: deposit,
          password: password.isNotEmpty ? password : '123456',
          debt2024: debt2024,
          debt2025: debt2025,
          annualFee: annualFee > 0 ? annualFee : 18000,
          createdAt: DateTime.now(),
        ));
      }

      setState(() {
        _preview = villas;
        _errors = errors;
        _loading = false;
      });
    } catch (e) {
      setState(() { _errors = ['Parse error: $e']; _loading = false; });
    }
  }

  Future<void> _importAll() async {
    if (_preview.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(villaRepositoryProvider);
      for (final villa in _preview) {
        await repo.add(villa);
      }
      setState(() { _imported = true; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_preview.length} villas imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/villas');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Import Villas from Excel',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline, color: AppTheme.darkBlue),
                      const SizedBox(width: 8),
                      const Text('Excel Format',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Your Excel file should have these columns:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _headerChip('OwnerName', required: true),
                        _headerChip('VillaNumber', required: true),
                        _headerChip('PhoneNumber', required: true),
                        _headerChip('Area'),
                        _headerChip('Deposit Amount'),
                        _headerChip('Password'),
                        _headerChip('2024 Debt'),
                        _headerChip('2025 Debt'),
                        _headerChip('Annual Fee'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '* Required columns are marked with a red dot\n'
                      '⚠️ Phone numbers must include country code (e.g. +201098868292)\n'
                      '🔑 Default password is 123456 if not provided\n'
                      '💰 Default annual fee is 18,000 if not provided',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pick file button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName ?? 'Choose Excel File'),
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],

            // Errors
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ Errors found:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      ..._errors.map((e) => Text('• $e',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ],

            // Preview
            if (_preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preview — ${_preview.length} villas ready',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                          fontSize: 16)),
                  TextButton(
                      onPressed: () =>
                          setState(() { _preview = []; _fileName = null; }),
                      child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _preview.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final v = _preview[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.darkBlue.withOpacity(0.1),
                      child: Text(v.villaNumber,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue)),
                    ),
                    title: Text(v.ownerName),
                    subtitle: Text(
                      '${v.phoneNumber}'
                      '${v.area > 0 ? '  •  ${v.area}m²' : ''}'
                      '${v.depositAmount > 0 ? '  •  Dep: ${v.depositAmount.toStringAsFixed(0)}' : ''}'
                      '${v.debt2024 > 0 ? '  •  D24: ${v.debt2024.toStringAsFixed(0)}' : ''}'
                      '${v.debt2025 > 0 ? '  •  D25: ${v.debt2025.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      '🔑 ${v.password}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _importAll,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Import ${_preview.length} Villas to Firebase'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerChip(String label, {bool required = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (required)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppTheme.darkBlue)),
        ],
      ),
    );
  }
}
