import '../cloud/supa_db.dart';
import '../models/announcement.dart';

/// Announcements, backed by Supabase (collection `announcements`).
class AnnouncementRepository {
  AnnouncementRepository();

  static const _collection = 'announcements';
  final SupaDb _db = SupaDb.instance;

  Stream<List<Announcement>> watchAll() {
    return _db.watch(_collection).map((docs) {
      final items =
          docs.map((d) => Announcement.fromMap(d.id, d.data)).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }
}
