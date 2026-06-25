import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

/// Allows admin to manually record a previous-year closing balance
/// (debt carried forward) for any villa.
///
/// This creates an AnnualSettlement record marked as "manual" so
/// the next year's settlement can use it as openingBalance.
class SetOpeningBalanceScreen extends ConsumerStatefulWidget {
  const SetOpeningBalanceScreen({super.key});

  @override
  ConsumerState<SetOpeningBalanceScreen> createState() =>
      _SetOpeningBalanceScreenState();
}

class _SetOpeningBalanceScreenState
    extends ConsumerState<SetOpeningBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _balanceCtrl = TextEditingController();
  Villa? _selectedVilla;
  int _selectedYear = DateTime.now().year - 1;
  bool _loading = false;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedVilla == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a villa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final balance = double.parse(_balanceCtrl.text.trim());
      final col = FirebaseFirestore.instance.collection('annualSettlements');

      // Check if a record already exists for this villa/year
      final existing = await col
          .where('villaId', isEqualTo: _selectedVilla!.id)
          .where('year', isEqualTo: _selectedYear)
          .limit(1)
          .get();

      final data = {
        'villaId': _selectedVilla!.id,
        'villaNumber': _selectedVilla!.villaNumber,
        'ownerName': _selectedVilla!.ownerName,
        'year': _selectedYear,
        'openingBalance': 0.0,
        'pricePerMeter': 0.0,
        'area': _selectedVilla!.area,
        'actualCost': 0.0,
        'depositAmount': _selectedVilla!.depositAmount,
        'depositRate': 0.0,
        'depositReturn': 0.0,
        'totalPaid': 0.0,
        'closingBalance': balance,
        'isManual': true, // flag so we know this was entered manually
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      if (existing.docs.isNotEmpty) {
        await col.doc(existing.docs.first.id).set(data);
      } else {
        await col.add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Balance set for Villa ${_selectedVilla!.villaNumber} — $_selectedYear',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        setState(() {
          _selectedVilla = null;
          _balanceCtrl.clear();
        });
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
    final villasAsync = ref.watch(villasProvider);
    final fmt = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(title: const Text('Set Previous Year Balance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use this screen to enter debts (مديونيات) from previous years.\n\n'
                        'The closing balance you enter here will automatically become '
                        'the opening balance for the following year\'s settlement.',
                        style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Year selector
              _sectionHeader('Select Year'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            setState(() => _selectedYear--),
                      ),
                      Text(
                        '$_selectedYear',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () =>
                            setState(() => _selectedYear++),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Villa selector
              _sectionHeader('Select Villa'),
              const SizedBox(height: 12),
              villasAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (villas) => DropdownButtonFormField<Villa>(
                  value: _selectedVilla,
                  decoration: const InputDecoration(
                    labelText: 'Villa *',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items: villas
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                                'Villa ${v.villaNumber} — ${v.ownerName}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVilla = v),
                  validator: (v) =>
                      v == null ? 'Please select a villa' : null,
                ),
              ),

              // Show villa details if selected
              if (_selectedVilla != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('Area',
                          '${fmt.format(_selectedVilla!.area)} m²'),
                      _miniStat('Annual Fee',
                          '${fmt.format(_selectedVilla!.annualFee)} EGP'),
                      _miniStat('Deposit',
                          '${fmt.format(_selectedVilla!.depositAmount)} EGP'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Balance input
              _sectionHeader('Closing Balance (Debt)'),
              const SizedBox(height: 4),
              Text(
                'Enter the total amount owed at end of $_selectedYear',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Closing Balance (EGP) *',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  hintText: 'e.g. 5000 (positive = owes, negative = credit)',
                  suffixText: 'EGP',
                  helperText:
                      'Positive = villa owes compound  |  Negative = compound owes villa',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null)
                    return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _loading
                        ? 'Saving...'
                        : 'Save Balance for $_selectedYear',
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.darkBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.darkBlue)),
        ],
      );

  Widget _miniStat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.darkBlue)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500)),
        ],
      );
}
