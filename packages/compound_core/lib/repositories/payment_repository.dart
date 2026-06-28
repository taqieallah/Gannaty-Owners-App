import '../cloud/supa_db.dart';
import '../models/payment.dart';

/// Payments, backed by Supabase (`documents` table, collection `payments`).
class PaymentRepository {
  PaymentRepository();

  static const _collection = 'payments';
  final SupaDb _db = SupaDb.instance;

  /// Stream all payments (admin use), newest year/month first.
  Stream<List<Payment>> watchAll() {
    return _db.watch(_collection).map((docs) {
      final payments = docs.map((d) => Payment.fromMap(d.id, d.data)).toList();
      payments.sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
      return payments;
    });
  }

  /// Stream payments for a specific villa (client use), sorted in Dart.
  Stream<List<Payment>> watchByVilla(String villaId) {
    return _db.watch(_collection).map((docs) {
      final payments = docs
          .map((d) => Payment.fromMap(d.id, d.data))
          .where((p) => p.villaId == villaId)
          .toList();
      payments.sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
      return payments;
    });
  }

  Future<String> add(Payment payment) => _db.add(_collection, payment.toMap());

  /// Batch import from Excel parse results.
  Future<void> batchAdd(List<Payment> payments) async {
    for (final p in payments) {
      await _db.add(_collection, p.toMap());
    }
  }

  Future<void> markPaid(String paymentId, bool isPaid) =>
      _db.update(_collection, paymentId, {'isPaid': isPaid});

  /// Update attachment URLs on a payment document.
  Future<void> updateAttachments(String paymentId, List<String> urls) =>
      _db.update(_collection, paymentId, {'attachments': urls});

  Future<void> delete(String paymentId) => _db.delete(_collection, paymentId);

  Future<int> countUnpaid() async {
    final docs = await _db.list(_collection);
    return docs
        .map((d) => Payment.fromMap(d.id, d.data))
        .where((p) => !p.isPaid)
        .length;
  }
}
