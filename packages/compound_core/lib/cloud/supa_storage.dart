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

  /// Receipts are immutable once issued, so a byte-for-byte re-download on
  /// every reopen is pure egress. Keep the most recent ones in memory, capped
  /// so a long session cannot grow without bound.
  static const int _cacheMaxBytes = 24 * 1024 * 1024;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static int _cacheBytes = 0;

  static Future<Uint8List> downloadBytes(String path) async {
    final key = objectKey(path);
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // re-insert: keeps the map in least-recently-used order
      return hit;
    }

    final bytes =
        await SupaConfig.client.storage.from(bucket).download(key);
    if (bytes.length <= _cacheMaxBytes) {
      _cache[key] = bytes;
      _cacheBytes += bytes.length;
      while (_cacheBytes > _cacheMaxBytes && _cache.isNotEmpty) {
        final oldest = _cache.keys.first;
        _cacheBytes -= _cache.remove(oldest)!.length;
      }
    }
    return bytes;
  }

  /// Drops the cached receipts — call on sign-out so one owner's receipts are
  /// never served to the next account on a shared device.
  static void clearCache() {
    _cache.clear();
    _cacheBytes = 0;
  }

  static String publicUrl(String path) =>
      SupaConfig.client.storage.from(bucket).getPublicUrl(objectKey(path));

  static Future<({String downloadUrl, String storagePath})> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
  }) async {
    final key = objectKey(storagePath);
    _cacheBytes -= _cache.remove(key)?.length ?? 0;
    await SupaConfig.client.storage.from(bucket).uploadBinary(
          key,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
            // Receipts are immutable — let the CDN and the device hold them for
            // a month rather than re-fetching on every view (default: 1 hour).
            cacheControl: '2592000',
          ),
        );
    return (
      downloadUrl: SupaConfig.client.storage.from(bucket).getPublicUrl(key),
      storagePath: storagePath,
    );
  }
}
