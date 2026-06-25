import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';

class AnnualSettlementScreen extends ConsumerStatefulWidget {
  const AnnualSettlementScreen({super.key});

  @override
  ConsumerState<AnnualSettlementScreen> createState() =>
      _AnnualSettlementScreenState();
}

class _AnnualSettlementScreenState
    extends ConsumerState<AnnualSettlementScreen> {
  int _selectedYear = DateTime.now().year;
  bool _running = false;
  String? _runningVilla;

  Future<void> _runAll(
      List<Villa> villas, AnnualSettings settings) async {
    setState(() => _running = true);
    try {
      final repo = ref.read(annualSettlementRepositoryProvider);
      for (final villa in villas) {
        setState(() => _runningVilla = 'Villa ${villa.villaNumber}...');
        await repo.settle(villa: villa, settings: settings);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Settlement complete for ${villas.length} villas — $_selectedYear'),
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
      if (mounted) setState(() { _running = false; _runningVilla = null; });
    }
  }

  Future<void> _runOne(Villa villa, AnnualSettings settings) async {
    setState(() { _running = true; _runningVilla = 'Villa ${villa.villaNumber}'; });
    try {
      await ref
          .read(annualSettlementRepositoryProvider)
          .settle(villa: villa, settings: settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Villa ${villa.villaNumber} settled'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(allSettlementsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _running = false; _runningVilla = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final villasAsync = ref.watch(villasProvider);
    final settingsAsync =
        ref.watch(annualSettingsProvider(_selectedYear));
    final settlementsAsync = ref.watch(allSettlementsProvider);
    final fmt = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Year-End Settlement'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.push('/settlements/opening-balance'),
            icon: const Icon(Icons.history_edu_outlined,
                color: Colors.white, size: 18),
            label: const Text('Prior Debts',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          TextButton.icon(
            onPressed: () =>
                context.push('/settlements/settings'),
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 18),
            label: const Text('Settings',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Year selector
          Container(
            color: AppTheme.darkBlue.withOpacity(0.05),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppTheme.darkBlue),
                  onPressed: _running
                      ? null
                      : () => setState(() => _selectedYear--),
                ),
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppTheme.darkBlue),
                  onPressed: _running
                      ? null
                      : () => setState(() => _selectedYear++),
                ),
              ],
            ),
          ),

          Expanded(
            child: settingsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (settings) {
                if (settings == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.settings_outlined,
                              size: 64,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No annual settings for $_selectedYear',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set the price per m² and deposit rate first',
                            style: TextStyle(
                                color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context
                                .push('/settlements/settings'),
                            icon: const Icon(Icons.settings),
                            label: const Text('Set Up Annual Settings'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return villasAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error: $e')),
                  data: (villas) {
                    if (villas.isEmpty) {
                      return const Center(
                          child: Text('No villas registered'));
                    }

                    final existingSettlements = settlementsAsync
                        .asData?.value
                        ?.where((s) => s.year == _selectedYear)
                        .toList() ??
                        [];
                    final settledIds = existingSettlements
                        .map((s) => s.villaId)
                        .toSet();

                    return Column(
                      children: [
                        // Settings summary bar
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _InfoChip(
                                  label: 'Price/m²',
                                  value:
                                      '${fmt.format(settings.pricePerMeter)} EGP'),
                              _InfoChip(
                                  label: 'Deposit Rate',
                                  value:
                                      '${(settings.depositRate * 100).toStringAsFixed(1)}%'),
                              _InfoChip(
                                  label: 'Settled',
                                  value:
                                      '${existingSettlements.length}/${villas.length}'),
                            ],
                          ),
                        ),

                        // Running indicator
                        if (_running)
                          Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                const SizedBox(width: 10),
                                Text('Processing $_runningVilla'),
                              ],
                            ),
                          ),

                        // Settle all button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _running
                                  ? null
                                  : () => _runAll(villas, settings),
                              icon: const Icon(Icons.calculate_outlined),
                              label: Text(
                                  'Run Settlement for ALL ${villas.length} Villas'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
                          ),
                        ),

                        // Villa list
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: villas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final villa = villas[i];
                              final settled =
                                  settledIds.contains(villa.id);
                              final existing = existingSettlements
                                  .where((s) => s.villaId == villa.id)
                                  .firstOrNull;

                              return _VillaSettlementCard(
                                villa: villa,
                                settings: settings,
                                settlement: existing,
                                settled: settled,
                                running: _running,
                                onSettle: () =>
                                    _runOne(villa, settings),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VillaSettlementCard extends StatelessWidget {
  final Villa villa;
  final AnnualSettings settings;
  final AnnualSettlement? settlement;
  final bool settled;
  final bool running;
  final VoidCallback onSettle;

  const _VillaSettlementCard({
    required this.villa,
    required this.settings,
    required this.settlement,
    required this.settled,
    required this.running,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final actualCost = settings.pricePerMeter * villa.area;
    final depositReturn = villa.depositAmount * settings.depositRate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.darkBlue.withOpacity(0.1),
                  child: Text(
                    villa.villaNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                        fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(villa.ownerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${fmt.format(villa.area)} m²  •  Deposit: ${fmt.format(villa.depositAmount)} EGP',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (settled)
                  Chip(
                    label: const Text('Settled',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.zero,
                  )
                else
                  Chip(
                    label: const Text('Pending',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                    backgroundColor: Colors.orange.shade600,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),

            const Divider(height: 20),

            // Calculation preview
            if (settlement != null) ...[
              _calcRow('Opening Balance',
                  '${fmt.format(settlement!.openingBalance)} EGP'),
              _calcRow(
                  'Actual Cost (${fmt.format(villa.area)}m² × ${fmt.format(settings.pricePerMeter)})',
                  '+ ${fmt.format(settlement!.actualCost)} EGP'),
              _calcRow(
                  'Deposit Return (${(settings.depositRate * 100).toStringAsFixed(1)}%)',
                  '− ${fmt.format(settlement!.depositReturn)} EGP'),
              _calcRow('Total Paid',
                  '− ${fmt.format(settlement!.totalPaid)} EGP'),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Closing Balance',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${settlement!.closingBalance >= 0 ? '' : ''}${fmt.format(settlement!.closingBalance)} EGP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: settlement!.closingBalance > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _calcRow(
                  'Estimated Cost (${fmt.format(villa.area)}m² × ${fmt.format(settings.pricePerMeter)})',
                  '${fmt.format(actualCost)} EGP'),
              _calcRow(
                  'Est. Deposit Return',
                  '${fmt.format(depositReturn)} EGP'),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: running ? null : onSettle,
                icon: Icon(
                    settled ? Icons.refresh : Icons.calculate_outlined,
                    size: 16),
                label:
                    Text(settled ? 'Re-run Settlement' : 'Settle Now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkBlue,
                  side: const BorderSide(color: AppTheme.darkBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600))),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}
