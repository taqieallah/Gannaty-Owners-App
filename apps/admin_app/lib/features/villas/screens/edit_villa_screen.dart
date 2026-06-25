import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class EditVillaScreen extends ConsumerStatefulWidget {
  final String villaId;
  const EditVillaScreen({super.key, required this.villaId});

  @override
  ConsumerState<EditVillaScreen> createState() => _EditVillaScreenState();
}

class _EditVillaScreenState extends ConsumerState<EditVillaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _villaNumberCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _debt2024Ctrl;
  late final TextEditingController _debt2025Ctrl;
  double _annualFee = 18000;
  bool _saving = false;
  Villa? _originalVilla;

  @override
  void initState() {
    super.initState();
    _villaNumberCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _areaCtrl = TextEditingController();
    _depositCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _debt2024Ctrl = TextEditingController();
    _debt2025Ctrl = TextEditingController();
  }

  void _populateFields(Villa villa) {
    if (_originalVilla != null) return; // already populated
    _originalVilla = villa;
    _villaNumberCtrl.text = villa.villaNumber;
    _ownerNameCtrl.text = villa.ownerName;
    _phoneCtrl.text = villa.phoneNumber;
    _areaCtrl.text = villa.area > 0 ? villa.area.toString() : '';
    _depositCtrl.text =
        villa.depositAmount > 0 ? villa.depositAmount.toString() : '';
    _passwordCtrl.text = villa.password;
    _debt2024Ctrl.text = villa.debt2024 > 0 ? villa.debt2024.toString() : '';
    _debt2025Ctrl.text = villa.debt2025 > 0 ? villa.debt2025.toString() : '';
    setState(() => _annualFee = villa.annualFee);
  }

  @override
  void dispose() {
    _villaNumberCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _areaCtrl.dispose();
    _depositCtrl.dispose();
    _passwordCtrl.dispose();
    _debt2024Ctrl.dispose();
    _debt2025Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalVilla == null) return;

    setState(() => _saving = true);
    try {
      final updated = _originalVilla!.copyWith(
        villaNumber: _villaNumberCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        area: double.parse(_areaCtrl.text.trim()),
        annualFee: _annualFee,
        depositAmount: _depositCtrl.text.trim().isEmpty
            ? 0
            : double.parse(_depositCtrl.text.trim()),
        password: _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : '123456',
        debt2024: _debt2024Ctrl.text.trim().isEmpty
            ? 0
            : double.parse(_debt2024Ctrl.text.trim()),
        debt2025: _debt2025Ctrl.text.trim().isEmpty
            ? 0
            : double.parse(_debt2025Ctrl.text.trim()),
      );
      await ref.read(villaRepositoryProvider).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Villa updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final villasAsync = ref.watch(villasProvider);

    return villasAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (villas) {
        final villa = villas.firstWhere(
          (v) => v.id == widget.villaId,
          orElse: () => Villa(
            id: '',
            villaNumber: '?',
            ownerName: '',
            phoneNumber: '',
            createdAt: DateTime.now(),
          ),
        );
        if (villa.id.isEmpty) {
          return const Scaffold(body: Center(child: Text('Villa not found')));
        }
        _populateFields(villa);

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Villa ${villa.villaNumber}'),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Villa Info ─────────────────────────────────────
                _sectionHeader('Villa Information'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _villaNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Villa Number *',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Owner Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+20XXXXXXXXXX',
                    border: OutlineInputBorder(),
                    helperText: 'Client uses this to sign in',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.trim().startsWith('+')) {
                      return 'Must start with + (e.g. +20...)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Login Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                    helperText: 'Client login password (default: 123456)',
                  ),
                ),
                const SizedBox(height: 28),

                // ── Financial Details ──────────────────────────────
                _sectionHeader('Financial Details'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Area (m²) *',
                    prefixIcon: Icon(Icons.straighten_outlined),
                    border: OutlineInputBorder(),
                    suffixText: 'm²',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final d = double.tryParse(v.trim());
                    if (d == null || d <= 0) return 'Enter a valid area';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Annual fee toggle
                const Text('Annual Fee',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FeeCard(
                        amount: 18000,
                        label: '18,000 EGP',
                        subtitle: '1,500 / month',
                        selected: _annualFee == 18000,
                        onTap: () => setState(() => _annualFee = 18000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeeCard(
                        amount: 24000,
                        label: '24,000 EGP',
                        subtitle: '2,000 / month',
                        selected: _annualFee == 24000,
                        onTap: () => setState(() => _annualFee = 24000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _depositCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Deposit Amount (EGP)',
                    prefixIcon: Icon(Icons.savings_outlined),
                    hintText: '0 if no deposit paid',
                    border: OutlineInputBorder(),
                    suffixText: 'EGP',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final d = double.tryParse(v.trim());
                      if (d == null || d < 0) return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),
                _sectionHeader('Opening Debts'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _debt2024Ctrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: '2024 Debt (EGP)',
                    prefixIcon: Icon(Icons.history_outlined),
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: 'EGP',
                    helperText: 'Opening debt from 2024',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _debt2025Ctrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: '2025 Debt (EGP)',
                    prefixIcon: Icon(Icons.history_outlined),
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: 'EGP',
                    helperText: 'Opening debt from 2025',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
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
  }
}

class _FeeCard extends StatelessWidget {
  final double amount;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _FeeCard({
    required this.amount,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.darkBlue.withOpacity(0.08)
              : Colors.grey.shade50,
          border: Border.all(
            color: selected ? AppTheme.darkBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_outlined,
              color: selected ? AppTheme.darkBlue : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        selected ? AppTheme.darkBlue : Colors.grey.shade700,
                    fontSize: 13)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
