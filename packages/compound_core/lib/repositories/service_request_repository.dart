import '../cloud/supa_db.dart';
import '../models/service_request.dart';
import 'villa_repository.dart';

/// Service requests, backed by Supabase (collection `serviceRequests`).
class ServiceRequestRepository {
  ServiceRequestRepository();

  static const _collection = 'serviceRequests';
  final SupaDb _db = SupaDb.instance;

  List<ServiceRequest> _sortedDesc(List<SupaDoc> docs) {
    final items =
        docs.map((d) => ServiceRequest.fromMap(d.id, d.data)).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Stream all requests (admin use), newest first.
  Stream<List<ServiceRequest>> watchAll() =>
      _db.watch(_collection).map(_sortedDesc);

  /// Stream requests for a specific client phone (client use).
  ///
  /// Scoped server-side to the owner's own `clientPhone` (the app writes it
  /// from `villa.phoneNumber`, the same value passed here) so the client never
  /// downloads other owners' requests. The normalized-phone compare is kept as
  /// a defensive filter (it can only narrow the already-scoped result).
  Stream<List<ServiceRequest>> watchByPhone(String phone) {
    final normalizedPhone = VillaRepository.normalizePhone(phone);
    return _db.watchWhere(_collection, 'clientPhone', phone).map((docs) =>
        _sortedDesc(docs)
            .where((r) =>
                VillaRepository.normalizePhone(r.clientPhone) == normalizedPhone)
            .toList());
  }

  Future<String> add(ServiceRequest request) =>
      _db.add(_collection, request.toMap());

  Future<void> updateStatus(
    String requestId,
    ServiceRequestStatus status, {
    String? adminNote,
  }) async {
    final update = <String, dynamic>{
      'status': status.firestoreValue,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (adminNote != null) update['adminNote'] = adminNote;
    await _db.update(_collection, requestId, update);
  }

  Future<int> countOpen() async {
    final docs = await _db.list(_collection);
    return docs
        .map((d) => ServiceRequest.fromMap(d.id, d.data))
        .where((r) =>
            r.status == ServiceRequestStatus.pending ||
            r.status == ServiceRequestStatus.inProgress)
        .length;
  }
}
