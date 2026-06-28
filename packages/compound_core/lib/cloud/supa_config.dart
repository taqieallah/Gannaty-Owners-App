import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for the owners app (Firebase replacement).
///
/// The publishable/anon key is a public client key protected by Row-Level
/// Security — safe to ship, exactly like the committed firebase_options.
class SupaConfig {
  SupaConfig._();

  static const String url = 'https://hgfrtxktcucqucanfqhi.supabase.co';

  // Supabase publishable (anon) key — public, RLS-protected.
  static const String anonKey =
      'sb_publishable_ywa7bOpp1qm8o1Feq7nZUQ_uFsuXcPE';

  /// Workspace partition holding all data the owners app reads. This is the
  /// same uid the main ERP uses, so owner accounts + compound collections live
  /// together in the `documents` table.
  static const String workspaceUid = '5nCpbFKDt1NyrXCw56HaattDVT42';

  static bool _initialized = false;

  /// Opens the Supabase client and restores any cached session.
  static Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
