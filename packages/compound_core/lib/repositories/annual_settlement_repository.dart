import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/annual_settlement.dart';
import '../models/annual_settings.dart';
import '../models/villa.dart';

class AnnualSettlementRepository {
  final _col = FirebaseFirestore.instance.collection('annualSettlements');
  final _payments = FirebaseFirestore.instance.collection('payments');

  /// Stream all settlements, newest year first
  Stream<List<AnnualSettlement>> watchAll() {
    return _col
        .orderBy('year', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AnnualSettlement.fromFirestore).toList());
  }

  /// Stream settlements for a specific villa.
  /// Sorted in Dart to avoid requiring a Firestore composite index
  /// on (villaId + year), which would need manual creation.
  Stream<List<AnnualSettlement>> watchByVilla(String villaId) {
    return _col
        .where('villaId', isEqualTo: villaId)
        .snapshots()
        .map((s) {
          final items =
              s.docs.map(AnnualSettlement.fromFirestore).toList();
          items.sort((a, b) => b.year.compareTo(a.year));
          return items;
        });
  }

  /// Get settlement for a specific villa + year — always reads from
  /// the server to avoid stale cache when re-running settlements.
  Future<AnnualSettlement?> getByVillaAndYear(
      String villaId, int year) async {
    final snap = await _col
        .where('villaId', isEqualTo: villaId)
        .where('year', isEqualTo: year)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    if (snap.docs.isEmpty) return null;
    return AnnualSettlement.fromFirestore(snap.docs.first);
  }

  /// Sum all PAID payments for a villa in a given year
  Future<double> getTotalPaid(String villaId, int year) async {
    final snap = await _payments
        .where('villaId', isEqualTo: villaId)
        .where('year', isEqualTo: year)
        .where('isPaid', isEqualTo: true)
        .get();
    return snap.docs.fold<double>(
        0, (sum, doc) => sum + ((doc['amount'] as num).toDouble()));
  }

  /// Calculate and save settlement for one villa.
  /// Returns the saved settlement.
  Future<AnnualSettlement> settle({
    required Villa villa,
    required AnnualSettings settings,
  }) async {
    // Get previous year's closing balance as opening balance
    final prev = await getByVillaAndYear(villa.id, settings.year - 1);
    final openingBalance = prev?.closingBalance ?? 0;

    final totalPaid = await getTotalPaid(villa.id, settings.year);

    final actualCost = settings.pricePerMeter * villa.area;
    final depositReturn = villa.depositAmount * settings.depositRate;
    final closingBalance =
        openingBalance + actualCost - depositReturn - totalPaid;

    final settlement = AnnualSettlement(
      id: '',
      villaId: villa.id,
      villaNumber: villa.villaNumber,
      ownerName: villa.ownerName,
      year: settings.year,
      openingBalance: openingBalance,
      pricePerMeter: settings.pricePerMeter,
      area: villa.area,
      actualCost: actualCost,
      depositAmount: villa.depositAmount,
      depositRate: settings.depositRate,
      depositReturn: depositReturn,
      totalPaid: totalPaid,
      closingBalance: closingBalance,
      createdAt: DateTime.now(),
    );

    // Check if settlement already exists for this villa/year — update if so
    final existing = await getByVillaAndYear(villa.id, settings.year);
    if (existing != null) {
      await _col.doc(existing.id).set(settlement.toFirestore());
      return AnnualSettlement.fromFirestore(
          await _col.doc(existing.id).get());
    } else {
      final ref = await _col.add(settlement.toFirestore());
      return AnnualSettlement.fromFirestore(await ref.get());
    }
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
