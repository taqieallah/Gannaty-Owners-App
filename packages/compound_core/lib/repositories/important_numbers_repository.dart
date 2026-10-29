import '../cloud/supa_db.dart';
import '../models/important_number.dart';

/// The compound's important numbers: one document (`config/important_numbers`)
/// written by the admin app, whose `items` list order is the display order.
class ImportantNumbersRepository {
  ImportantNumbersRepository();

  static const _collection = 'config';
  static const _docId = 'important_numbers';
  final SupaDb _db = SupaDb.instance;

  Stream<List<ImportantNumber>> watch() {
    return _db.watch(_collection).map((docs) {
      final doc = docs.where((d) => d.id == _docId).firstOrNull;
      return parse(doc?.data);
    });
  }

  static List<ImportantNumber> parse(Map<String, dynamic>? data) {
    final items = data?['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((m) => ImportantNumber.fromMap(Map<String, dynamic>.from(m)))
        .where((n) => n.name.isNotEmpty && n.phone.isNotEmpty)
        .toList();
  }
}
