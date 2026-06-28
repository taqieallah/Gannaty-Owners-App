import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../utils/cloud_dates.dart';

enum ServiceRequestType { maintenance, complaint, other }

enum ServiceRequestStatus { pending, inProgress, solved }

extension ServiceRequestTypeX on ServiceRequestType {
  String get label {
    switch (this) {
      case ServiceRequestType.maintenance:
        return 'Maintenance';
      case ServiceRequestType.complaint:
        return 'Complaint';
      case ServiceRequestType.other:
        return 'Other';
    }
  }
}

extension ServiceRequestStatusX on ServiceRequestStatus {
  String get label {
    switch (this) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.solved:
        return 'Solved';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ServiceRequestStatus.pending:
        return 'pending';
      case ServiceRequestStatus.inProgress:
        return 'in_progress';
      case ServiceRequestStatus.solved:
        return 'solved';
    }
  }

  static ServiceRequestStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return ServiceRequestStatus.inProgress;
      case 'solved':
        return ServiceRequestStatus.solved;
      default:
        return ServiceRequestStatus.pending;
    }
  }
}

class ServiceRequest extends Equatable {
  final String id;
  final String villaId;
  final String villaNumber;
  final String clientPhone;
  final String clientName;
  final ServiceRequestType type;
  final String description;
  final ServiceRequestStatus status;
  final String? imageUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceRequest({
    required this.id,
    required this.villaId,
    required this.villaNumber,
    required this.clientPhone,
    required this.clientName,
    required this.type,
    required this.description,
    required this.status,
    this.imageUrl,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) =>
      ServiceRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> data) {
    return ServiceRequest(
      id: id,
      villaId: (data['villaId'] ?? '').toString(),
      villaNumber: (data['villaNumber'] ?? '').toString(),
      clientPhone: (data['clientPhone'] ?? '').toString(),
      clientName: data['clientName'] as String? ?? '',
      type: ServiceRequestType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? ''),
        orElse: () => ServiceRequestType.other,
      ),
      description: (data['description'] ?? '').toString(),
      status: ServiceRequestStatusX.fromString(
          data['status'] as String? ?? 'pending'),
      imageUrl: data['imageUrl'] as String?,
      adminNote: data['adminNote'] as String?,
      createdAt: parseFlexDate(data['createdAt']),
      updatedAt: parseFlexDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'villaId': villaId,
        'villaNumber': villaNumber,
        'clientPhone': clientPhone,
        'clientName': clientName,
        'type': type.name,
        'description': description,
        'status': status.firestoreValue,
        'imageUrl': imageUrl,
        'adminNote': adminNote,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  Map<String, dynamic> toMap() => {
        'villaId': villaId,
        'villaNumber': villaNumber,
        'clientPhone': clientPhone,
        'clientName': clientName,
        'type': type.name,
        'description': description,
        'status': status.firestoreValue,
        'imageUrl': imageUrl,
        'adminNote': adminNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ServiceRequest copyWith({
    ServiceRequestStatus? status,
    String? adminNote,
  }) {
    return ServiceRequest(
      id: id,
      villaId: villaId,
      villaNumber: villaNumber,
      clientPhone: clientPhone,
      clientName: clientName,
      type: type,
      description: description,
      status: status ?? this.status,
      imageUrl: imageUrl,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, status, updatedAt];
}
