import '../cloud/supa_db.dart';
import '../models/annual_settings.dart';

/// Annual settings, backed by Supabase (collection `annualSettings`,
/// doc id = year). The owners app reads one year's settings at a time.
class AnnualSettingsRepository {
  static const _collection = 'annualSettings';
  final SupaDb _db = SupaDb.instance;

  Stream<AnnualSettings?> watch(int year) {
    final id = year.toString();
    return _db.watch(_collection).map((docs) {
      for (final d in docs) {
        if (d.id == id) return AnnualSettings.fromMap(d.id, d.data);
      }
      return null;
    });
  }

  Future<AnnualSettings?> get(int year) async {
    final d = await _db.getById(_collection, year.toString());
    return d == null ? null : AnnualSettings.fromMap(d.id, d.data);
  }

  Future<void> save(AnnualSettings settings) =>
      _db.set(_collection, settings.year.toString(), settings.toMap());
}
