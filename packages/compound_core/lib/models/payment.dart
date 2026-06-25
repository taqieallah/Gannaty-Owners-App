import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String villaId;
  final String villaNumber;
  final int month;
  final int year;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? description;
  final String receiptNumber;
  final List<String> attachments; // Firebase Storage download URLs
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.villaId,
    required this.villaNumber,
    required this.month,
    required this.year,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.description,
    this.receiptNumber = '',
    this.attachments = const [],
    required this.createdAt,
  });

  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now());

  String get monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $year';
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      villaId: data['villaId'] as String,
      villaNumber: data['villaNumber'] as String,
      month: data['month'] as int,
      year: data['year'] as int,
      amount: (data['amount'] as num).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isPaid: data['isPaid'] as bool,
      description: data['description'] as String?,
      receiptNumber: data['receiptNumber']?.toString() ?? '',
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'] as List)
          : const [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'villaId': villaId,
        'villaNumber': villaNumber,
        'month': month,
        'year': year,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'isPaid': isPaid,
        'description': description,
        'receiptNumber': receiptNumber,
        'attachments': attachments,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Payment copyWith({
    bool? isPaid,
    String? receiptNumber,
    List<String>? attachments,
  }) {
    return Payment(
      id: id,
      villaId: villaId,
      villaNumber: villaNumber,
      month: month,
      year: year,
      amount: amount,
      dueDate: dueDate,
      isPaid: isPaid ?? this.isPaid,
      description: description,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, villaId, month, year, isPaid, receiptNumber, attachments];
}
