import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors I:\Rebrand's Owner + OwnerYearSettings + computed balance.
/// Fields match the Firestore document structure written by OwnersRepo.
class OwnerAccount {
  const OwnerAccount({
    required this.id,
    required this.name,
    required this.villaNo,
    required this.villaArea,
    required this.depositPaid,
    required this.initialMaintenance,
    required this.meterPrice,
    required this.depositReturn,
    required this.openingBalance,
    required this.totalCharges,
    required this.totalPayments,
    required this.year,
  });

  final int id;
  final String name;
  final String villaNo;
  final double villaArea;
  final double depositPaid;
  final double initialMaintenance;

  // Year-specific settings
  final double meterPrice;
  final double depositReturn;
  final double openingBalance;

  // Aggregated from transactions for [year]
  final double totalCharges;
  final double totalPayments;
  final int year;

  /// الصيانة الفعلية: إذا في سعر متر يُطبَّق، وإلا الصيانة المبدئية
  double get maintenance =>
      (meterPrice > 0 && villaArea > 0) ? villaArea * meterPrice : initialMaintenance;

  /// المديونية الكاملة = صيانة + رصيد أول المدة − عائد الوديعة + CHARGEs − payments
  /// Positive = owner owes, Negative = compound owes owner (credit)
  double get balance =>
      maintenance + openingBalance - depositReturn + totalCharges - totalPayments;

  bool get isCredit => balance < 0;

  static OwnerAccount fromFirestore({
    required DocumentSnapshot<Map<String, dynamic>> ownerDoc,
    required Map<String, Object?>? yearSettings,
    required double totalCharges,
    required double totalPayments,
    required int year,
  }) {
    final d = ownerDoc.data()!;
    final ys = yearSettings ?? const <String, Object?>{};
    return OwnerAccount(
      id: (d['Id'] as num).toInt(),
      name: (d['Name'] as String?) ?? '',
      villaNo: (d['VillaNo'] as String?) ?? '',
      villaArea: (d['VillaArea'] as num?)?.toDouble() ?? 0,
      depositPaid: (d['DepositPaid'] as num?)?.toDouble() ?? 0,
      initialMaintenance: (d['InitialMaintenance'] as num?)?.toDouble() ?? 0,
      meterPrice: (ys['MeterPrice'] as num?)?.toDouble() ?? 0,
      depositReturn: (ys['DepositReturn'] as num?)?.toDouble() ?? 0,
      openingBalance: (ys['OpeningBalance'] as num?)?.toDouble() ?? 0,
      totalCharges: totalCharges,
      totalPayments: totalPayments,
      year: year,
    );
  }
}
