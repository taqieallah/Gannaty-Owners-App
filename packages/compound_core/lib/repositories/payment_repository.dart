import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  /// Stream all payments (admin use)
  Stream<List<Payment>> watchAll() {
    return _collection
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Payment.fromFirestore).toList());
  }

  /// Stream payments for a specific villa (client use).
  /// Sorting is done in Dart to avoid requiring a Firestore composite index
  /// on (villaId + year + month), which would need manual creation.
  Stream<List<Payment>> watchByVilla(String villaId) {
    return _collection
        .where('villaId', isEqualTo: villaId)
        .snapshots()
        .map((snap) {
          final payments =
              snap.docs.map(Payment.fromFirestore).toList();
          payments.sort((a, b) {
            final y = b.year.compareTo(a.year);
            return y != 0 ? y : b.month.compareTo(a.month);
          });
          return payments;
        });
  }

  Future<String> add(Payment payment) async {
    final ref = await _collection.add(payment.toFirestore());
    return ref.id;
  }

  /// Batch import from Excel parse results
  Future<void> batchAdd(List<Payment> payments) async {
    const chunkSize = 500;
    for (var i = 0; i < payments.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = payments.sublist(
          i, i + chunkSize > payments.length ? payments.length : i + chunkSize);
      for (final p in chunk) {
        final ref = _collection.doc();
        batch.set(ref, p.toFirestore());
      }
      await batch.commit();
    }
  }

  Future<void> markPaid(String paymentId, bool isPaid) async {
    await _collection.doc(paymentId).update({'isPaid': isPaid});
  }

  /// Update attachment URLs on a payment document
  Future<void> updateAttachments(String paymentId, List<String> urls) async {
    await _collection.doc(paymentId).update({'attachments': urls});
  }

  Future<void> delete(String paymentId) async {
    await _collection.doc(paymentId).delete();
  }

  Future<int> countUnpaid() async {
    final snap =
        await _collection.where('isPaid', isEqualTo: false).count().get();
    return snap.count ?? 0;
  }
}
