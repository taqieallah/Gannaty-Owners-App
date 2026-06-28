import '../cloud/supa_db.dart';
import '../models/annual_settlement.dart';
import '../models/annual_settings.dart';
import '../models/payment.dart';
import '../models/villa.dart';

/// Annual settlements, backed by Supabase (collection `annualSettlements`).
class AnnualSettlementRepository {
  static const _collection = 'annualSettlements';
  static const _paymentsCollection = 'payments';
  final SupaDb _db = SupaDb.instance;

  /// Stream all settlements, newest year first.
  Stream<List<AnnualSettlement>> watchAll() {
    return _db.watch(_collection).map((docs) {
      final items =
          docs.map((d) => AnnualSettlement.fromMap(d.id, d.data)).toList();
      items.sort((a, b) => b.year.compareTo(a.year));
      return items;
    });
  }

  /// Stream settlements for a specific villa, newest year first.
  Stream<List<AnnualSettlement>> watchByVilla(String villaId) {
    return _db.watch(_collection).map((docs) {
      final items = docs
          .map((d) => AnnualSettlement.fromMap(d.id, d.data))
          .where((s) => s.villaId == villaId)
          .toList();
      items.sort((a, b) => b.year.compareTo(a.year));
      return items;
    });
  }

  Future<AnnualSettlement?> getByVillaAndYear(String villaId, int year) async {
    final docs = await _db.list(_collection);
    for (final d in docs) {
      final s = AnnualSettlement.fromMap(d.id, d.data);
      if (s.villaId == villaId && s.year == year) return s;
    }
    return null;
  }

  /// Sum all PAID payments for a villa in a given year.
  Future<double> getTotalPaid(String villaId, int year) async {
    final docs = await _db.list(_paymentsCollection);
    return docs
        .map((d) => Payment.fromMap(d.id, d.data))
        .where((p) => p.villaId == villaId && p.year == year && p.isPaid)
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Calculate and save settlement for one villa; returns the saved settlement.
  Future<AnnualSettlement> settle({
    required Villa villa,
    required AnnualSettings settings,
  }) async {
    final prev = await getByVillaAndYear(villa.id, settings.year - 1);
    final openingBalance = prev?.closingBalance ?? 0;

    final totalPaid = await getTotalPaid(villa.id, settings.year);

    final actualCost = settings.pricePerMeter * villa.area;
    final depositReturn = villa.depositAmount * settings.depositRate;
    final closingBalance =
        openingBalance + actualCost - depositReturn - totalPaid;

    var settlement = AnnualSettlement(
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

    final existing = await getByVillaAndYear(villa.id, settings.year);
    if (existing != null) {
      await _db.set(_collection, existing.id, settlement.toMap());
      return settlement = AnnualSettlement.fromMap(
          existing.id, settlement.toMap());
    }
    final id = await _db.add(_collection, settlement.toMap());
    return AnnualSettlement.fromMap(id, settlement.toMap());
  }

  Future<void> delete(String id) => _db.delete(_collection, id);
}
