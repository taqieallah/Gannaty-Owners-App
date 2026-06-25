import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class AnnualSettingsScreen extends ConsumerStatefulWidget {
  const AnnualSettingsScreen({super.key});

  @override
  ConsumerState<AnnualSettingsScreen> createState() =>
      _AnnualSettingsScreenState();
}

class _AnnualSettingsScreenState
    extends ConsumerState<AnnualSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  int _selectedYear = DateTime.now().year;
  bool _loading = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill(int year) async {
    if (_prefilled) return;
    final existing =
        await ref.read(annualSettingsRepositoryProvider).get(year);
    if (existing != null && mounted) {
      _priceCtrl.text = existing.pricePerMeter.toString();
      _rateCtrl.text = (existing.depositRate * 100).toString();
      setState(() => _prefilled = true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final settings = AnnualSettings(
        id: _selectedYear.toString(),
        year: _selectedYear,
        pricePerMeter: double.parse(_priceCtrl.text.trim()),
        depositRate: double.parse(_rateCtrl.text.trim()) / 100,
        createdAt: DateTime.now(),
      );
      await ref.read(annualSettingsRepositoryProvider).save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved for $_selectedYear'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync =
        ref.watch(annualSettingsProvider(_selectedYear));

    // Pre-fill fields when data loads
    settingsAsync.whenData((s) {
      if (s != null && !_prefilled) {
        _priceCtrl.text = s.pricePerMeter.toString();
        _rateCtrl.text = (s.depositRate * 100).toStringAsFixed(2);
        _prefilled = true;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Annual Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year selector card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Year',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setState(() {
                              _selectedYear--;
                              _prefilled = false;
                              _priceCtrl.clear();
                              _rateCtrl.clear();
                            }),
                          ),
                          Text(
                            '$_selectedYear',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setState(() {
                              _selectedYear++;
                              _prefilled = false;
                              _priceCtrl.clear();
                              _rateCtrl.clear();
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Current saved settings banner
              settingsAsync.when(
                data: (s) => s != null
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saved: ${NumberFormat('#,##0.##').format(s.pricePerMeter)} EGP/m²  •  '
                                '${(s.depositRate * 100).toStringAsFixed(2)}% deposit rate',
                                style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 10),
                            Text('No settings saved for $_selectedYear yet',
                                style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price per m² (EGP) *',
                  prefixIcon: Icon(Icons.price_change_outlined),
                  hintText: 'e.g. 85',
                  suffixText: 'EGP/m²',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null ||
                      double.parse(v.trim()) <= 0)
                    return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Deposit Return Rate (%) *',
                  prefixIcon: Icon(Icons.percent_outlined),
                  hintText: 'e.g. 5',
                  suffixText: '%',
                  helperText: 'Applied to each villa\'s deposit amount',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final d = double.tryParse(v.trim());
                  if (d == null || d < 0 || d > 100)
                    return 'Enter a value between 0 and 100';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Preview calculation
              if (_priceCtrl.text.isNotEmpty && _rateCtrl.text.isNotEmpty)
                _PreviewCard(
                  pricePerMeter:
                      double.tryParse(_priceCtrl.text) ?? 0,
                  depositRate:
                      (double.tryParse(_rateCtrl.text) ?? 0) / 100,
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _loading
                        ? 'Saving...'
                        : 'Save Settings for $_selectedYear',
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final double pricePerMeter;
  final double depositRate;

  const _PreviewCard(
      {required this.pricePerMeter, required this.depositRate});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.darkBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview Example (300 m² villa, 20,000 deposit)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.darkBlue)),
          const SizedBox(height: 10),
          _row('Actual Cost', '${fmt.format(pricePerMeter * 300)} EGP'),
          _row('Deposit Return',
              '${fmt.format(20000 * depositRate)} EGP (${(depositRate * 100).toStringAsFixed(1)}% of 20,000)'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
