import 'package:equatable/equatable.dart';

import '../utils/cloud_dates.dart';

class Announcement extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> data) {
    return Announcement(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: parseFlexDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, title, createdAt];
}
