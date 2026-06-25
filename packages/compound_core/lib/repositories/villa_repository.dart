import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/villa.dart';

class VillaRepository {
  final FirebaseFirestore _firestore;

  VillaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('villas');

  Stream<List<Villa>> watchAll() {
    return _collection
        .orderBy('villaNumber')
        .snapshots()
        .map((snap) => snap.docs.map(Villa.fromFirestore).toList());
  }

  Future<Villa?> findByPhone(String phone) async {
    final rawPhone = phone.trim();
    final snap = await _collection
        .where('phoneNumber', isEqualTo: rawPhone)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return Villa.fromFirestore(snap.docs.first);
    }

    final normalized = _normalizePhone(rawPhone);
    if (normalized.isEmpty) return null;

    final all = await _collection.get();
    for (final doc in all.docs) {
      final villa = Villa.fromFirestore(doc);
      if (_normalizePhone(villa.phoneNumber) == normalized) {
        return villa;
      }
    }

    return null;
  }

  Future<String> add(Villa villa) async {
    final ref = await _collection.add(villa.toFirestore());
    return ref.id;
  }

  Future<void> update(Villa villa) async {
    await _collection.doc(villa.id).update(villa.toFirestore());
  }

  /// Update a client's password and clear the first-login flag
  Future<void> updatePassword(String villaId, String newPassword) async {
    await _collection.doc(villaId).update({
      'password': newPassword,
      'isFirstLogin': false,
    });
  }

  Future<void> delete(String villaId) async {
    await _collection.doc(villaId).delete();
  }

  Future<Villa?> getById(String villaId) async {
    final doc = await _collection.doc(villaId).get();
    if (!doc.exists) return null;
    return Villa.fromFirestore(doc);
  }

  static String normalizePhone(String value) => _normalizePhone(value);

  static String _normalizePhone(String value) {
    const arabicIndic = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    var normalized = value.trim();
    arabicIndic.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });

    normalized = normalized.replaceAll(RegExp(r'[^0-9+]'), '');

    if (normalized.startsWith('+20')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('20') && normalized.length > 10) {
      normalized = '0${normalized.substring(2)}';
    }

    if (normalized.startsWith('0020')) {
      normalized = '0${normalized.substring(4)}';
    }

    return normalized;
  }
}
