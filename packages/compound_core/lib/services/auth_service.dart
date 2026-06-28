import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud/supa_config.dart';

/// Authentication backed by Supabase (Firebase replacement).
///
/// Client owners authenticate by validating phone+password against their owner
/// record, then signing in anonymously (same model the Firebase build used).
class AuthService {
  AuthService();

  GoTrueClient get _auth => SupaConfig.client.auth;

  User? get currentUser => _auth.currentUser;

  /// Emits the current [User] (or null) on every auth state change.
  Stream<User?> get authStateChanges =>
      _auth.onAuthStateChange.map((s) => s.session?.user);

  // ── Admin (email/password) ──────────────────────────────────────────────
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  // ── Client (anonymous — used after phone+password validation) ────────────
  Future<AuthResponse> signInAnonymously() => _auth.signInAnonymously();

  Future<void> signOut() => _auth.signOut();

  String? get currentPhone => _auth.currentUser?.phone;
  String? get currentEmail => _auth.currentUser?.email;
}
