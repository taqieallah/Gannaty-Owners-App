import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationEntry {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  const NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.millisecondsSinceEpoch,
      };

  factory NotificationEntry.fromJson(Map<String, dynamic> json) =>
      NotificationEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(json['receivedAt'] as int),
      );
}

class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationEntry>> {
  static const _key = 'client_notification_history';
  static const _maxEntries = 50;

  @override
  Future<List<NotificationEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  }

  Future<void> add({required String title, required String body}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _load(prefs);
    final entry = NotificationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now(),
    );
    final updated = [entry, ...entries].take(_maxEntries).toList();
    await _save(prefs, updated);
    state = AsyncData(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData([]);
  }

  Future<List<NotificationEntry>> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((s) {
          try {
            return NotificationEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationEntry>()
        .toList();
    return Future.value(entries);
  }

  Future<void> _save(
      SharedPreferences prefs, List<NotificationEntry> entries) async {
    await prefs.setStringList(
      _key,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

final notificationHistoryProvider =
    AsyncNotifierProvider<NotificationHistoryNotifier, List<NotificationEntry>>(
  NotificationHistoryNotifier.new,
);
