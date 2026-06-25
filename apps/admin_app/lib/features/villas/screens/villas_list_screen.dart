import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:compound_core/compound_core.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_scaffold.dart';

class VillasListScreen extends ConsumerStatefulWidget {
  const VillasListScreen({super.key});
  @override
  ConsumerState<VillasListScreen> createState() => _VillasListScreenState();
}

class _VillasListScreenState extends ConsumerState<VillasListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final villasAsync = ref.watch(villasProvider);

    return AppScaffold(
      title: 'Villas',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by villa number or owner...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/villas/import'),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Import from Excel'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: villasAsync.when(
              data: (villas) {
                final filtered = villas.where((v) {
                  if (_search.isEmpty) return true;
                  return v.villaNumber.toLowerCase().contains(_search) ||
                      v.ownerName.toLowerCase().contains(_search) ||
                      v.phoneNumber.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No villas found',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) =>
                      _VillaTile(villa: filtered[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/villas/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Villa'),
      ),
    );
  }
}

class _VillaTile extends ConsumerWidget {
  final Villa villa;
  const _VillaTile({required this.villa});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsUpdate = villa.area <= 0;
    final fmt = NumberFormat('#,##0.##');
    return Card(
      child: ListTile(
        onTap: () => context.go('/villas/${villa.id}'),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.darkBlue.withOpacity(0.1),
              child: Text(
                villa.villaNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                    fontSize: 12),
              ),
            ),
            if (needsUpdate)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high,
                      size: 9, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(villa.ownerName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: needsUpdate
            ? const Text('⚠️ Area not set — tap Edit',
                style: TextStyle(color: Colors.orange, fontSize: 12))
            : Text(
                '${fmt.format(villa.area)} m²  •  ${fmt.format(villa.annualFee)} EGP/yr',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') context.go('/villas/${villa.id}/edit');
            if (action == 'delete') _confirmDelete(context, ref);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ])),
            PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ])),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Villa'),
        content: Text(
            'Delete Villa ${villa.villaNumber} (${villa.ownerName})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(villaRepositoryProvider).delete(villa.id);
    }
  }
}
