import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import 'edit_villa_screen.dart';

final _villaPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, villaId) {
  return ref.watch(paymentRepositoryProvider).watchByVilla(villaId);
});

final _villaRequestsProvider =
    StreamProvider.family<List<ServiceRequest>, String>((ref, phone) {
  return ref.watch(serviceRequestRepositoryProvider).watchByPhone(phone);
});

class VillaDetailScreen extends ConsumerWidget {
  final String villaId;
  const VillaDetailScreen({super.key, required this.villaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villasAsync = ref.watch(villasProvider);

    return villasAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (villas) {
        final villa = villas.firstWhere((v) => v.id == villaId,
            orElse: () => Villa(
                id: '',
                villaNumber: '?',
                ownerName: 'Not found',
                phoneNumber: '',
                createdAt: DateTime.now()));

        final paymentsAsync = ref.watch(_villaPaymentsProvider(villaId));
        final requestsAsync =
            ref.watch(_villaRequestsProvider(villa.phoneNumber));

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Villa ${villa.villaNumber}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Villa',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditVillaScreen(villaId: villaId),
                    ),
                  ),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.payment), text: 'Payments'),
                  Tab(icon: Icon(Icons.build), text: 'Requests'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Villa info card
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppTheme.darkBlue.withOpacity(0.1),
                              child: Text(villa.villaNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkBlue,
                                      fontSize: 12)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(villa.ownerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(villa.phoneNumber,
                                      style: const TextStyle(
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (villa.area > 0 || villa.depositAmount > 0) ...[
                          const Divider(height: 20),
                          _villaFinancialRow(villa),
                        ] else ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange.shade600, size: 16),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Area & deposit not set — tap ✏️ to edit',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Payments tab
                      paymentsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Error: $e')),
                        data: (payments) {
                          if (payments.isEmpty) {
                            return const Center(
                                child: Text('No payments recorded'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            itemCount: payments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) =>
                                _PaymentTile(payment: payments[i]),
                          );
                        },
                      ),
                      // Requests tab
                      requestsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Error: $e')),
                        data: (requests) {
                          if (requests.isEmpty) {
                            return const Center(
                                child: Text('No requests submitted'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            itemCount: requests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) => ListTile(
                              title: Text(requests[i].type.label),
                              subtitle: Text(requests[i].description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              trailing: Chip(
                                  label: Text(requests[i].status.label,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white)),
                                  backgroundColor:
                                      _statusColor(requests[i].status)),
                              onTap: () => context
                                  .go('/requests/${requests[i].id}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () =>
                  context.go('/payments/add?villaId=$villaId'),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment'),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(ServiceRequestStatus s) {
    switch (s) {
      case ServiceRequestStatus.pending:
        return Colors.orange;
      case ServiceRequestStatus.inProgress:
        return Colors.blue;
      case ServiceRequestStatus.solved:
        return Colors.green;
    }
  }

  Widget _villaFinancialRow(Villa villa) {
    final fmt = NumberFormat('#,##0.##');
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _chip(Icons.straighten_outlined,
            '${fmt.format(villa.area)} m²', Colors.blue.shade700),
        _chip(Icons.account_balance_wallet_outlined,
            '${fmt.format(villa.annualFee)} EGP/yr', Colors.indigo.shade700),
        _chip(Icons.savings_outlined,
            'Deposit: ${fmt.format(villa.depositAmount)} EGP',
            Colors.teal.shade700),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Card(
      child: ListTile(
        leading: Icon(
          payment.isPaid ? Icons.check_circle : Icons.warning_rounded,
          color: payment.isPaid
              ? Colors.green
              : payment.isOverdue
                  ? Colors.red
                  : Colors.orange,
        ),
        title: Text(payment.monthLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Due: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${fmt.format(payment.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              payment.isPaid
                  ? 'Paid'
                  : payment.isOverdue
                      ? 'Overdue'
                      : 'Pending',
              style: TextStyle(
                  fontSize: 12,
                  color: payment.isPaid
                      ? Colors.green
                      : payment.isOverdue
                          ? Colors.red
                          : Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
