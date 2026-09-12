import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud/supa_config.dart';

/// Result of a successful owner login: the access token plus the owner's
/// public profile (never the password).
class OwnerLoginResult {
  const OwnerLoginResult({required this.accessToken, required this.owner});
  final String accessToken;
  final Map<String, dynamic> owner;
}

/// Thrown when owner login fails, with a machine-readable [code] the UI maps
/// to an Arabic message.
class OwnerLoginException implements Exception {
  const OwnerLoginException(this.code);
  final String code; // e.g. phone_not_found, wrong_password, network
  @override
  String toString() => 'OwnerLoginException($code)';
}

/// Authentication backed by Supabase (Firebase replacement).
///
/// Owner clients authenticate via the `owner-login` Edge Function (which
/// verifies phone+password server-side and mints an `owner_id` JWT). Admin
/// email/password auth is retained for the admin build.
class AuthService {
  AuthService();

  GoTrueClient get _auth => SupaConfig.client.auth;

  // ── Admin auth state (admin build) ───────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges =>
      _auth.onAuthStateChange.map((s) => s.session?.user);

  // ── Owner (client) login via Edge Function ───────────────────────────────

  /// Verifies phone+password server-side and returns the owner token + profile.
  /// Throws [OwnerLoginException] with a code on failure.
  Future<OwnerLoginResult> ownerLogin({
    required String phone,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final res = await SupaConfig.client.functions.invoke(
        'owner-login',
        body: {
          'phone': phone.trim(),
          'password': password.trim(),
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        },
      );
      final data = res.data;
      if (res.status != 200 || data is! Map) {
        final code = (data is Map ? data['error']?.toString() : null) ??
            'login_failed';
        throw OwnerLoginException(code);
      }
      final token = data['access_token']?.toString() ?? '';
      final owner = (data['owner'] as Map?)?.cast<String, dynamic>() ?? {};
      if (token.isEmpty || owner.isEmpty) {
        throw const OwnerLoginException('login_failed');
      }
      return OwnerLoginResult(accessToken: token, owner: owner);
    } on OwnerLoginException {
      rethrow;
    } on FunctionException catch (e) {
      final details = e.details;
      final code =
          (details is Map ? details['error']?.toString() : null) ?? 'network';
      throw OwnerLoginException(code);
    } catch (_) {
      throw const OwnerLoginException('network');
    }
  }

  // ── Admin (email/password) — admin build only ────────────────────────────
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Owner sessions are token-only (no GoTrue session); clearing the token is
    // handled by the caller via SupaConfig.setOwnerToken(null).
    try {
      await _auth.signOut();
    } catch (_) {/* third-party mode: no GoTrue session to sign out */}
  }

  String? get currentEmail => _auth.currentUser?.email;
}
