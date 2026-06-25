import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

  factory AnnualSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnualSettings(
      id: doc.id,
      year: data['year'] as int,
      pricePerMeter: (data['pricePerMeter'] as num).toDouble(),
      depositRate: (data['depositRate'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'year': year,
        'pricePerMeter': pricePerMeter,
        'depositRate': depositRate,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [id, year, pricePerMeter, depositRate];
}
