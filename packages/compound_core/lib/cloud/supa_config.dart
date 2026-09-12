import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for the owners app (Firebase replacement).
///
/// The publishable/anon key is a public client key protected by Row-Level
/// Security — safe to ship, exactly like the committed firebase_options.
///
/// Owner clients authenticate through the `owner-login` Edge Function, which
/// returns a signed JWT carrying an `owner_id` claim. That token is held here
/// and supplied to Supabase as the access token (third-party auth), so RLS can
/// scope every read/write to the calling owner. No anonymous auth is used.
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

  /// The current owner access token (from the `owner-login` Edge Function).
  /// Supplied to Supabase per request via the [Supabase.initialize] callback.
  static String? _ownerToken;

  static bool _initialized = false;

  /// Opens the Supabase client in third-party-auth mode: every request uses
  /// [_ownerToken] as the bearer token (empty before login).
  static Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      accessToken: () async => _ownerToken ?? '',
    );
    _initialized = true;
  }

  /// Sets (or clears) the owner token used for subsequent Supabase requests.
  ///
  /// Also authorizes Realtime with the token — in third-party-auth mode the
  /// token is not propagated to the Realtime socket automatically, so without
  /// this RLS filters out every change event and the client only sees updates
  /// on a fresh REST fetch (i.e. after a restart).
  static void setOwnerToken(String? token) {
    _ownerToken = (token != null && token.isNotEmpty) ? token : null;
    try {
      client.realtime.setAuth(_ownerToken);
    } catch (_) {/* client not ready yet — applied on next set */}
  }

  static String? get ownerToken => _ownerToken;

  static SupabaseClient get client => Supabase.instance.client;
}
