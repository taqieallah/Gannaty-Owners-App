import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supa_config.dart';

/// A document read from Supabase: its id plus the JSON payload. Mirrors what a
/// Firestore `DocumentSnapshot` exposed (`id` + `data()`), so repositories /
/// models can map it the same way via `Model.fromMap(doc.id, doc.data)`.
class SupaDoc {
  const SupaDoc(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

/// Generic document store over the Supabase `documents` table
/// (uid, collection, doc_id, data jsonb), scoped to [SupaConfig.workspaceUid].
///
/// This is the Supabase replacement for the Firestore collections the owners
/// app used. All compound + owner-account data lives in one table/partition.
class SupaDb {
  SupaDb._();
  static final SupaDb instance = SupaDb._();

  SupabaseClient get _c => SupaConfig.client;
  String get _uid => SupaConfig.workspaceUid;

  SupaDoc _row(Map<String, dynamic> r) {
    final raw = r['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return SupaDoc((r['doc_id'] ?? '').toString(), data);
  }

  /// All documents in [collection].
  Future<List<SupaDoc>> list(String collection) async {
    final rows = await _c
        .from('documents')
        .select('doc_id, data')
        .eq('uid', _uid)
        .eq('collection', collection);
    return rows.map<SupaDoc>((r) => _row(r)).toList();
  }

  /// Documents in [collection] where [field] equals [value] (string compare).
  Future<List<SupaDoc>> queryEq(
    String collection,
    String field,
    Object? value, {
    int? limit,
  }) async {
    var q = _c
        .from('documents')
        .select('doc_id, data')
        .eq('uid', _uid)
        .eq('collection', collection)
        .eq('data->>$field', value?.toString() ?? '');
    final rows = limit != null ? await q.limit(limit) : await q;
    return rows.map<SupaDoc>((r) => _row(r)).toList();
  }

  Future<SupaDoc?> getById(String collection, String id) async {
    final row = await _c
        .from('documents')
        .select('doc_id, data')
        .eq('uid', _uid)
        .eq('collection', collection)
        .eq('doc_id', id)
        .maybeSingle();
    return row == null ? null : _row(row);
  }

  /// Inserts a new document with a generated id; returns the id.
  Future<String> add(String collection, Map<String, dynamic> data) async {
    final id = _generateId();
    await set(collection, id, data, merge: false);
    return id;
  }

  /// Upserts a document. [merge] true = shallow-merge top-level keys.
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _c.rpc('set_document', params: {
      'p_uid': _uid,
      'p_collection': collection,
      'p_doc_id': id,
      'p_data': _jsonSafe(data),
      'p_merge': merge,
    });
  }

  /// Merges [partial] into the existing document (Firestore `.update` semantics).
  Future<void> update(
          String collection, String id, Map<String, dynamic> partial) =>
      set(collection, id, partial, merge: true);

  Future<void> delete(String collection, String id) async {
    await _c
        .from('documents')
        .delete()
        .eq('uid', _uid)
        .eq('collection', collection)
        .eq('doc_id', id);
  }

  /// Realtime stream of the whole [collection]. Emits the current list on
  /// connect and again on every insert/update/delete — same shape as a
  /// Firestore collection `.snapshots()`.
  Stream<List<SupaDoc>> watch(String collection) {
    final controller = StreamController<List<SupaDoc>>();
    RealtimeChannel? channel;

    Future<void> emit() async {
      try {
        controller.add(await list(collection));
      } catch (_) {/* keep stream alive on transient errors */}
    }

    controller.onListen = () {
      emit();
      channel = _c
          .channel('docs:$_uid:$collection')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'documents',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'collection',
              value: collection,
            ),
            callback: (_) => emit(),
          )
          .subscribe();
    };
    controller.onCancel = () async {
      final ch = channel;
      if (ch != null) await _c.removeChannel(ch);
    };
    return controller.stream;
  }

  String _generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = (Random().nextInt(1 << 32)).toRadixString(36);
    return '$ts$rnd';
  }

  Object? _jsonSafe(Object? v) {
    if (v is DateTime) return v.toIso8601String();
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
    if (v is Iterable) return v.map(_jsonSafe).toList();
    return v;
  }
}
