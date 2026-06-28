import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../utils/cloud_dates.dart';

/// Holds the compound-wide settings for a specific year.
/// Admin sets pricePerMeter and depositRate once per year.
/// Document ID = year.toString() e.g. "2025"
class AnnualSettings extends Equatable {
  final String id;
  final int year;
  final double pricePerMeter; // EGP per m²
  final double depositRate;   // e.g. 0.05 = 5%
  final DateTime createdAt;

  const AnnualSettings({
    required this.id,
    required this.year,
    required this.pricePerMeter,
    required this.depositRate,
    required this.createdAt,
  });

  factory AnnualSettings.fromFirestore(DocumentSnapshot doc) =>
      AnnualSettings.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory AnnualSettings.fromMap(String id, Map<String, dynamic> data) {
    return AnnualSettings(
      id: id,
      year: (data['year'] as num?)?.toInt() ?? 0,
      pricePerMeter: (data['pricePerMeter'] as num?)?.toDouble() ?? 0,
      depositRate: (data['depositRate'] as num?)?.toDouble() ?? 0,
      createdAt: parseFlexDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'year': year,
        'pricePerMeter': pricePerMeter,
        'depositRate': depositRate,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Map<String, dynamic> toMap() => {
        'year': year,
        'pricePerMeter': pricePerMeter,
        'depositRate': depositRate,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, year, pricePerMeter, depositRate];
}
