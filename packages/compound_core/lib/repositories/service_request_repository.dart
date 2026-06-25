import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request.dart';
import 'villa_repository.dart';

class ServiceRequestRepository {
  final FirebaseFirestore _firestore;

  ServiceRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('serviceRequests');

  /// Stream all requests (admin use), newest first
  Stream<List<ServiceRequest>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceRequest.fromFirestore).toList());
  }

  /// Stream requests for a specific client phone (client use)
  Stream<List<ServiceRequest>> watchByPhone(String phone) {
    final normalizedPhone = VillaRepository.normalizePhone(phone);
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(ServiceRequest.fromFirestore)
              .where(
                (request) =>
                    VillaRepository.normalizePhone(request.clientPhone) ==
                    normalizedPhone,
              )
              .toList(),
        );
  }

  Future<String> add(ServiceRequest request) async {
    final ref = await _collection.add(request.toFirestore());
    return ref.id;
  }

  Future<void> updateStatus(
    String requestId,
    ServiceRequestStatus status, {
    String? adminNote,
  }) async {
    final update = <String, dynamic>{
      'status': status.firestoreValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (adminNote != null) update['adminNote'] = adminNote;
    await _collection.doc(requestId).update(update);
  }

  Future<int> countOpen() async {
    final snap = await _collection
        .where('status', whereIn: ['pending', 'in_progress'])
        .count()
        .get();
    return snap.count ?? 0;
  }
}
