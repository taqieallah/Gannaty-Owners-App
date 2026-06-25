import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

  factory AnnualSettlement.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnualSettlement(
      id: doc.id,
      villaId: d['villaId'] as String,
      villaNumber: d['villaNumber'] as String,
      ownerName: d['ownerName'] as String,
      year: d['year'] as int,
      openingBalance: (d['openingBalance'] as num).toDouble(),
      pricePerMeter: (d['pricePerMeter'] as num).toDouble(),
      area: (d['area'] as num).toDouble(),
      actualCost: (d['actualCost'] as num).toDouble(),
      depositAmount: (d['depositAmount'] as num).toDouble(),
      depositRate: (d['depositRate'] as num).toDouble(),
      depositReturn: (d['depositReturn'] as num).toDouble(),
      totalPaid: (d['totalPaid'] as num).toDouble(),
      closingBalance: (d['closingBalance'] as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

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
