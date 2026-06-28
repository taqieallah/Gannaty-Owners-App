import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Villa extends Equatable {
  final String id;
  final String villaNumber;
  final String ownerName;
  final String phoneNumber;
  final double area;          // Area in m²
  final double annualFee;     // 18000 or 24000
  final double depositAmount; // Deposit paid by this owner
  final String password;      // Login password (default set by admin)
  final double debt2024;      // Opening debt from 2024
  final double debt2025;      // Opening debt from 2025
  final bool isFirstLogin;    // true until client sets their own password
  final DateTime createdAt;

  const Villa({
    required this.id,
    required this.villaNumber,
    required this.ownerName,
    required this.phoneNumber,
    this.area = 0,
    this.annualFee = 18000,
    this.depositAmount = 0,
    this.password = '123456',
    this.debt2024 = 0,
    this.debt2025 = 0,
    this.isFirstLogin = true,
    required this.createdAt,
  });

  factory Villa.fromFirestore(DocumentSnapshot doc) =>
      Villa.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  /// Backend-neutral builder. `createdAt` may be a Firestore Timestamp, an ISO
  /// string (Supabase), or epoch millis.
  factory Villa.fromMap(String id, Map<String, dynamic> data) {
    return Villa(
      id: id,
      villaNumber: (data['villaNumber'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      area: (data['area'] as num?)?.toDouble() ?? 0,
      annualFee: (data['annualFee'] as num?)?.toDouble() ?? 18000,
      depositAmount: (data['depositAmount'] as num?)?.toDouble() ?? 0,
      password: data['password'] as String? ?? '123456',
      debt2024: (data['debt2024'] as num?)?.toDouble() ?? 0,
      debt2025: (data['debt2025'] as num?)?.toDouble() ?? 0,
      isFirstLogin: data['isFirstLogin'] as bool? ?? true,
      createdAt: parseDate(data['createdAt']),
    );
  }

  /// Parses a date stored as Firestore Timestamp, ISO-8601 string, or millis.
  static DateTime parseDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  /// Backend-neutral map (dates as ISO strings — Supabase stores jsonb).
  Map<String, dynamic> toMap() => {
        'villaNumber': villaNumber,
        'ownerName': ownerName,
        'phoneNumber': phoneNumber,
        'area': area,
        'annualFee': annualFee,
        'depositAmount': depositAmount,
        'password': password,
        'debt2024': debt2024,
        'debt2025': debt2025,
        'isFirstLogin': isFirstLogin,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'villaNumber': villaNumber,
        'ownerName': ownerName,
        'phoneNumber': phoneNumber,
        'area': area,
        'annualFee': annualFee,
        'depositAmount': depositAmount,
        'password': password,
        'debt2024': debt2024,
        'debt2025': debt2025,
        'isFirstLogin': isFirstLogin,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Villa copyWith({
    String? villaNumber,
    String? ownerName,
    String? phoneNumber,
    double? area,
    double? annualFee,
    double? depositAmount,
    String? password,
    double? debt2024,
    double? debt2025,
    bool? isFirstLogin,
  }) {
    return Villa(
      id: id,
      villaNumber: villaNumber ?? this.villaNumber,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      area: area ?? this.area,
      annualFee: annualFee ?? this.annualFee,
      depositAmount: depositAmount ?? this.depositAmount,
      password: password ?? this.password,
      debt2024: debt2024 ?? this.debt2024,
      debt2025: debt2025 ?? this.debt2025,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, villaNumber, ownerName, phoneNumber, area, annualFee, depositAmount];
}
