import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supa_config.dart';

/// Supabase Storage helper for the owners app (receipts + request images).
/// Object keys are ASCII-sanitized to match the ERP's CloudStorage so links
/// resolve to the same migrated objects.
class SupaStorage {
  static const String bucket = 'receipts';

  static String objectKey(String path) {
    var p = path.trim();
    if (p.startsWith('/')) p = p.substring(1);
    if (p.startsWith('$bucket/')) p = p.substring(bucket.length + 1);
    return p.replaceAll(RegExp(r'[^A-Za-z0-9._/-]'), '_');
  }

  static Future<Uint8List> downloadBytes(String path) =>
      SupaConfig.client.storage.from(bucket).download(objectKey(path));

  static String publicUrl(String path) =>
      SupaConfig.client.storage.from(bucket).getPublicUrl(objectKey(path));

  static Future<({String downloadUrl, String storagePath})> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
  }) async {
    final key = objectKey(storagePath);
    await SupaConfig.client.storage.from(bucket).uploadBinary(
          key,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return (
      downloadUrl: SupaConfig.client.storage.from(bucket).getPublicUrl(key),
      storagePath: storagePath,
    );
  }
}
