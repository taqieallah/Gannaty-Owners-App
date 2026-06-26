import 'package:cloud_firestore/cloud_firestore.dart';

import 'owner_statement.dart';

/// Mirrors the ERP's Owner + OwnerYearSettings + computed balance.
/// Fields match the Firestore document structure written by OwnersRepo.
///
/// When a precomputed [statement] is available (pushed by the ERP), all
/// displayed figures come from it so the numbers + breakdown match the ERP's
/// Excel/PDF exactly — the client no longer recomputes.
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
    this.statement,
  });

  /// Precomputed statement from the ERP (authoritative when present).
  final OwnerStatement? statement;

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

  /// الصيانة الفعلية — من الكشف المحسوب إن وُجد، وإلا الحساب القديم.
  double get maintenance =>
      statement?.maintenance ??
      ((meterPrice > 0 && villaArea > 0)
          ? villaArea * meterPrice
          : initialMaintenance);

  /// المديونية الكاملة — من الكشف المحسوب إن وُجد (يطابق الإكسيل تمامًا).
  /// Positive = owner owes, Negative = compound owes owner (credit)
  double get balance =>
      statement?.closingBalance ??
      (maintenance +
          openingBalance -
          depositReturn +
          totalCharges -
          totalPayments);

  bool get isCredit => balance < 0;

  static OwnerAccount fromFirestore({
    required DocumentSnapshot<Map<String, dynamic>> ownerDoc,
    required Map<String, Object?>? yearSettings,
    required double totalCharges,
    required double totalPayments,
    required int year,
    OwnerStatement? statement,
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
      // Prefer the statement's authoritative figures for the breakdown rows.
      meterPrice:
          statement?.meterPrice ?? (ys['MeterPrice'] as num?)?.toDouble() ?? 0,
      depositReturn: statement?.depositReturn ??
          (ys['DepositReturn'] as num?)?.toDouble() ??
          0,
      openingBalance: statement?.openingBalance ??
          (ys['OpeningBalance'] as num?)?.toDouble() ??
          0,
      totalCharges: statement?.totalCharges ?? totalCharges,
      totalPayments: statement?.totalPayments ?? totalPayments,
      year: year,
      statement: statement,
    );
  }
}
