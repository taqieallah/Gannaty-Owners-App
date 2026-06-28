import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../utils/cloud_dates.dart';

/// Year-end financial settlement for a single villa.
///
/// Formula:
///   actualCost    = pricePerMeter × area
///   depositReturn = depositAmount × depositRate
///   closingBalance = openingBalance + actualCost - depositReturn - totalPaid
///
/// closingBalance becomes next year's openingBalance.
class AnnualSettlement extends Equatable {
  final String id;
  final String villaId;
  final String villaNumber;
  final String ownerName;
  final int year;

  // Opening balance (= last year's closing balance, 0 for first year)
  final double openingBalance;

  // Cost calculation
  final double pricePerMeter;
  final double area;
  final double actualCost; // pricePerMeter × area

  // Deposit
  final double depositAmount;
  final double depositRate;
  final double depositReturn; // depositAmount × depositRate

  // Payments made during the year
  final double totalPaid;

  // Final balance (positive = owner owes, negative = compound owes owner)
  final double closingBalance;

  final DateTime createdAt;

  const AnnualSettlement({
    required this.id,
    required this.villaId,
    required this.villaNumber,
    required this.ownerName,
    required this.year,
    required this.openingBalance,
    required this.pricePerMeter,
    required this.area,
    required this.actualCost,
    required this.depositAmount,
    required this.depositRate,
    required this.depositReturn,
    required this.totalPaid,
    required this.closingBalance,
    required this.createdAt,
  });

  factory AnnualSettlement.fromFirestore(DocumentSnapshot doc) =>
      AnnualSettlement.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory AnnualSettlement.fromMap(String id, Map<String, dynamic> d) {
    double n(String k) => (d[k] as num?)?.toDouble() ?? 0;
    return AnnualSettlement(
      id: id,
      villaId: (d['villaId'] ?? '').toString(),
      villaNumber: (d['villaNumber'] ?? '').toString(),
      ownerName: (d['ownerName'] ?? '').toString(),
      year: (d['year'] as num?)?.toInt() ?? 0,
      openingBalance: n('openingBalance'),
      pricePerMeter: n('pricePerMeter'),
      area: n('area'),
      actualCost: n('actualCost'),
      depositAmount: n('depositAmount'),
      depositRate: n('depositRate'),
      depositReturn: n('depositReturn'),
      totalPaid: n('totalPaid'),
      closingBalance: n('closingBalance'),
      createdAt: parseFlexDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'villaId': villaId,
        'villaNumber': villaNumber,
        'ownerName': ownerName,
        'year': year,
        'openingBalance': openingBalance,
        'pricePerMeter': pricePerMeter,
        'area': area,
        'actualCost': actualCost,
        'depositAmount': depositAmount,
        'depositRate': depositRate,
        'depositReturn': depositReturn,
        'totalPaid': totalPaid,
        'closingBalance': closingBalance,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'villaId': villaId,
        'villaNumber': villaNumber,
        'ownerName': ownerName,
        'year': year,
        'openingBalance': openingBalance,
        'pricePerMeter': pricePerMeter,
        'area': area,
        'actualCost': actualCost,
        'depositAmount': depositAmount,
        'depositRate': depositRate,
        'depositReturn': depositReturn,
        'totalPaid': totalPaid,
        'closingBalance': closingBalance,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [id, villaId, year];
}
