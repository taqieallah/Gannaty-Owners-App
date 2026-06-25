import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});
  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
      ServiceRequest req, ServiceRequestStatus newStatus) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(serviceRequestRepositoryProvider)
          .updateStatus(req.id, newStatus,
              adminNote: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${newStatus.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allRequestsProvider);

    return requestsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (requests) {
        final req = requests.firstWhere(
          (r) => r.id == widget.requestId,
          orElse: () => ServiceRequest(
            id: '',
            villaId: '',
            villaNumber: '?',
            clientPhone: '',
            clientName: 'Unknown',
            type: ServiceRequestType.other,
            description: 'Not found',
            status: ServiceRequestStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (req.adminNote != null && _noteCtrl.text.isEmpty) {
          _noteCtrl.text = req.adminNote!;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Request – Villa ${req.villaNumber}'),
            actions: [
              if (req.status != ServiceRequestStatus.solved)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.tonal(
                    onPressed: _saving
                        ? null
                        : () => _updateStatus(
                            req, ServiceRequestStatus.solved),
                    child: const Text('Mark Solved'),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor(req.status).withOpacity(0.1),
                    border: Border.all(
                        color: _statusColor(req.status).withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.circle,
                        color: _statusColor(req.status), size: 12),
                    const SizedBox(width: 8),
                    Text(req.status.label,
                        style: TextStyle(
                            color: _statusColor(req.status),
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                        'Updated: ${DateFormat('dd MMM yyyy').format(req.updatedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Request info
                _InfoCard(children: [
                  _InfoRow('Villa', req.villaNumber),
                  _InfoRow('Client', req.clientName),
                  _InfoRow('Phone', req.clientPhone),
                  _InfoRow('Type', req.type.label),
                  _InfoRow('Submitted',
                      DateFormat('dd MMM yyyy – HH:mm').format(req.createdAt)),
                ]),
                const SizedBox(height: 16),

                Text('Description',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(req.description),
                ),

                if (req.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  Text('Attached Photo',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(req.imageUrl!,
                        height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],

                const SizedBox(height: 24),
                Text('Admin Note',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a note for this request...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Status update buttons
                if (req.status != ServiceRequestStatus.solved) ...[
                  Text('Update Status',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (req.status == ServiceRequestStatus.pending)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _updateStatus(
                                    req, ServiceRequestStatus.inProgress),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Working'),
                          ),
                        ),
                      if (req.status == ServiceRequestStatus.inProgress) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _updateStatus(
                                    req, ServiceRequestStatus.solved),
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Solved'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
