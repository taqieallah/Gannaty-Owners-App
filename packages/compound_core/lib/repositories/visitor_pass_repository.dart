import '../cloud/supa_db.dart';
import '../models/visitor_pass.dart';

/// The signed-in owner's visitor passes. Reads are scoped to the owner by RLS;
/// creating and revoking go through server functions so codes can't be forged.
class VisitorPassRepository {
  final SupaDb _db = SupaDb.instance;
  static const _collection = 'visitor_passes';

  /// Newest first.
  Future<List<VisitorPass>> list() async {
    final docs = await _db.list(_collection);
    final passes = docs.map((d) => VisitorPass.fromMap(d.data)).toList()
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));
    return passes;
  }

  Future<VisitorPass> create({
    required String name,
    required int hours,
    required int maxUses,
    String note = '',
  }) async {
    final res = await _db.callRpc('visitor_pass_create', {
      'p_name': name,
      'p_hours': hours,
      'p_max_uses': maxUses,
      'p_note': note,
    });
    return VisitorPass.fromMap(Map<String, dynamic>.from(res as Map));
  }

  Future<bool> revoke(String code) async {
    final res = await _db.callRpc('visitor_pass_revoke', {'p_code': code});
    return res == true;
  }
}
