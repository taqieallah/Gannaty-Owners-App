import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class AddVillaScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddVillaScreen({super.key, this.editId});

  @override
  ConsumerState<AddVillaScreen> createState() => _AddVillaScreenState();
}

class _AddVillaScreenState extends ConsumerState<AddVillaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '123456');
  final _debt2024Ctrl = TextEditingController();
  final _debt2025Ctrl = TextEditingController();
  double _annualFee = 18000;
  bool _loading = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _ownerCtrl.dispose();
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
    setState(() => _loading = true);

    try {
      final repo = ref.read(villaRepositoryProvider);
      final villa = Villa(
        id: '',
        villaNumber: _numberCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        area: double.tryParse(_areaCtrl.text.trim()) ?? 0,
        annualFee: _annualFee,
        depositAmount: double.tryParse(_depositCtrl.text.trim()) ?? 0,
        password: _passwordCtrl.text.trim().isNotEmpty
            ? _passwordCtrl.text.trim()
            : '123456',
        debt2024: double.tryParse(_debt2024Ctrl.text.trim()) ?? 0,
        debt2025: double.tryParse(_debt2025Ctrl.text.trim()) ?? 0,
        createdAt: DateTime.now(),
      );
      await repo.add(villa);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Villa added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/villas');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Villa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Basic Info
              _sectionHeader('Basic Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Villa Number *',
                  prefixIcon: Icon(Icons.home_work_outlined),
                  hintText: 'e.g. A-12',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Owner Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+201098868292',
                  helperText: 'Client uses this to sign in',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 8) return 'Enter a valid phone number';
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
                  hintText: '123456',
                  helperText: 'Default: 123456. Client can change it later.',
                ),
              ),

              const SizedBox(height: 28),
              _sectionHeader('Financial Details'),
              const SizedBox(height: 12),

              // Area field
              TextFormField(
                controller: _areaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'Villa Area (m²) *',
                  prefixIcon: Icon(Icons.square_foot_outlined),
                  hintText: 'e.g. 250',
                  suffixText: 'm²',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null ||
                      double.parse(v.trim()) <= 0)
                    return 'Enter a valid area';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Annual fee selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Annual Maintenance Fee *',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FeeOption(
                              label: '18,000 EGP',
                              sublabel: '1,500 / month',
                              selected: _annualFee == 18000,
                              onTap: () =>
                                  setState(() => _annualFee = 18000),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeeOption(
                              label: '24,000 EGP',
                              sublabel: '2,000 / month',
                              selected: _annualFee == 24000,
                              onTap: () =>
                                  setState(() => _annualFee = 24000),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _depositCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (EGP)',
                  prefixIcon: Icon(Icons.savings_outlined),
                  hintText: 'e.g. 10000',
                  helperText: 'Leave 0 if no deposit was paid',
                ),
              ),

              const SizedBox(height: 28),
              _sectionHeader('Opening Debts'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _debt2024Ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: '2024 Debt (EGP)',
                  prefixIcon: Icon(Icons.history_outlined),
                  hintText: '0',
                  helperText: 'Opening debt from 2024',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debt2025Ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: '2025 Debt (EGP)',
                  prefixIcon: Icon(Icons.history_outlined),
                  hintText: '0',
                  helperText: 'Opening debt from 2025',
                ),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Villa',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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

class _FeeOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _FeeOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.darkBlue
              : AppTheme.darkBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? AppTheme.darkBlue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: selected ? Colors.white : AppTheme.darkBlue)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? Colors.white70
                        : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
