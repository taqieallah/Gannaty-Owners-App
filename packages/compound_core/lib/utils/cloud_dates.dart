import 'package:cloud_firestore/cloud_firestore.dart';

/// Parses a date stored as a Firestore [Timestamp] (Firebase), an ISO-8601
/// string (Supabase jsonb), epoch millis, or an already-parsed [DateTime].
DateTime parseFlexDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}
