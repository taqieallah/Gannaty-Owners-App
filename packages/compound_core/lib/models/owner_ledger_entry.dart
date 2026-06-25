/// Mirrors I:\Rebrand's OwnerTransaction Firestore document.
/// Fields match the capitalized keys written by OwnersRepo.
class OwnerLedgerEntry {
  const OwnerLedgerEntry({
    required this.id,
    required this.ownerId,
    required this.txDate,
    required this.txType,
    this.category,
    required this.amount,
    this.refNo,
    this.description,
    this.notes,
    this.receiptUrl,
  });

  final int id;
  final int ownerId;
  final String txDate; // ISO yyyy-MM-dd
  final String txType; // "CHARGE" or "PAYMENT"
  final String? category;
  final double amount;
  final int? refNo;
  final String? description;
  final String? notes;
  /// Firebase Storage download URL saved by the admin when uploading a receipt.
  final String? receiptUrl;

  bool get isPayment => txType.toUpperCase() == 'PAYMENT';
  bool get isCharge => !isPayment;

  static OwnerLedgerEntry fromMap(Map<String, Object?> m) => OwnerLedgerEntry(
        id: (m['Id'] as num?)?.toInt() ?? 0,
        ownerId: (m['OwnerId'] as num?)?.toInt() ?? 0,
        txDate: (m['TxDate'] as String?) ?? '',
        txType: (m['TxType'] as String?) ?? 'CHARGE',
        category: m['Category'] as String?,
        amount: (m['Amount'] as num?)?.toDouble() ?? 0,
        refNo: (m['RefNo'] as num?)?.toInt(),
        description: m['Description'] as String?,
        notes: m['Notes'] as String?,
        receiptUrl: m['ReceiptUrl'] as String?,
      );
}
