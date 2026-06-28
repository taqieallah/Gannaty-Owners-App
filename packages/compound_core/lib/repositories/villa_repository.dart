import '../cloud/supa_db.dart';
import '../models/villa.dart';

/// Villas, backed by Supabase (`documents` table, collection `villas`).
class VillaRepository {
  VillaRepository();

  static const _collection = 'villas';
  final SupaDb _db = SupaDb.instance;

  Stream<List<Villa>> watchAll() {
    return _db.watch(_collection).map((docs) {
      final villas = docs.map((d) => Villa.fromMap(d.id, d.data)).toList();
      villas.sort((a, b) => a.villaNumber.compareTo(b.villaNumber));
      return villas;
    });
  }

  Future<Villa?> findByPhone(String phone) async {
    final rawPhone = phone.trim();
    final exact = await _db.queryEq(_collection, 'phoneNumber', rawPhone, limit: 1);
    if (exact.isNotEmpty) {
      return Villa.fromMap(exact.first.id, exact.first.data);
    }

    final normalized = _normalizePhone(rawPhone);
    if (normalized.isEmpty) return null;

    final all = await _db.list(_collection);
    for (final d in all) {
      final villa = Villa.fromMap(d.id, d.data);
      if (_normalizePhone(villa.phoneNumber) == normalized) {
        return villa;
      }
    }
    return null;
  }

  Future<String> add(Villa villa) => _db.add(_collection, villa.toMap());

  Future<void> update(Villa villa) =>
      _db.update(_collection, villa.id, villa.toMap());

  /// Update a client's password and clear the first-login flag.
  Future<void> updatePassword(String villaId, String newPassword) =>
      _db.update(_collection, villaId, {
        'password': newPassword,
        'isFirstLogin': false,
      });

  Future<void> delete(String villaId) => _db.delete(_collection, villaId);

  Future<Villa?> getById(String villaId) async {
    final d = await _db.getById(_collection, villaId);
    return d == null ? null : Villa.fromMap(d.id, d.data);
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
