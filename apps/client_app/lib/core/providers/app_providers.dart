import 'dart:async';
import 'dart:convert';

import 'package:compound_core/compound_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final villaRepositoryProvider =
    Provider<VillaRepository>((ref) => VillaRepository());
final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) => AnnouncementRepository());
final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());
final serviceRequestRepositoryProvider =
    Provider<ServiceRequestRepository>((ref) => ServiceRequestRepository());
final annualSettlementRepositoryProvider =
    Provider<AnnualSettlementRepository>(
      (ref) => AnnualSettlementRepository(),
    );

final ownerAccountRepositoryProvider = Provider<OwnerAccountRepository>((ref) {
  return OwnerAccountRepository();
});
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Villa?>(SessionController.new);

/// Owner session backed by an `owner_id` JWT from the `owner-login` Edge
/// Function. The token is held in [SupaConfig] and supplied to Supabase per
/// request, so RLS scopes all reads/writes to this owner. No anonymous auth.
class SessionController extends AsyncNotifier<Villa?> {
  static const _villaIdKey = 'client_villa_id';
  static const _villaPhoneKey = 'client_villa_phone';
  static const _tokenKey = 'client_owner_token';
  static const _ownerMapKey = 'client_owner_map';
  static const _biometricPhoneKey = 'biometric_phone';

  // ── Session restore ──────────────────────────────────────────────────────

  @override
  Future<Villa?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _restoreFromStorage(prefs);
  }

  /// Restores the session from a stored, unexpired token (no network).
  Future<Villa?> _restoreFromStorage(SharedPreferences prefs) async {
    final token = prefs.getString(_tokenKey);
    final ownerJson = prefs.getString(_ownerMapKey);
    if (token == null || !_tokenValid(token) || ownerJson == null) {
      await _clearSession(prefs);
      return null;
    }
    try {
      final map = (json.decode(ownerJson) as Map).cast<String, dynamic>();
      // Trust the token's owner_id over a possibly-stale saved profile (an old
      // login may have stored a precision-lost Id).
      final tokenOwnerId = _ownerIdFromToken(token);
      if (tokenOwnerId != null && tokenOwnerId.isNotEmpty) {
        map['Id'] = tokenOwnerId;
      }
      SupaConfig.setOwnerToken(token);
      // Keep the device token fresh for payment push (best-effort, no await).
      unawaited(_refreshOwnerFcm());
      return OwnerAccountRepository.buildVillaFromOwnerMap(map);
    } catch (_) {
      await _clearSession(prefs);
      return null;
    }
  }

  /// Persists the current device FCM token on the signed-in owner's record so
  /// the push-owner-transaction function can reach this device. Best-effort.
  Future<void> _refreshOwnerFcm() async {
    try {
      final t = await NotificationService.currentToken();
      if (t == null || t.isEmpty) return;
      await ref.read(ownerAccountRepositoryProvider).saveOwnFcm(t);
    } catch (_) {/* non-critical */}
  }

  // ── Sign in ──────────────────────────────────────────────────────────────

  Future<String?> signIn({
    required String phone,
    required String password,
  }) async {
    final auth = ref.read(authServiceProvider);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    try {
      // Best-effort device token so the owner receives payment push notifications.
      final fcm = await NotificationService.currentToken();
      final result = await auth
          .ownerLogin(
              phone: phone.trim(), password: password.trim(), fcmToken: fcm)
          .timeout(const Duration(seconds: 20));

      SupaConfig.setOwnerToken(result.accessToken);
      final villa = OwnerAccountRepository.buildVillaFromOwnerMap(result.owner);
      await _persistSession(prefs, result.accessToken, result.owner, villa);
      state = AsyncData(villa);
      return null;
    } on OwnerLoginException catch (e) {
      SupaConfig.setOwnerToken(null);
      state = const AsyncData(null);
      return _loginErrorMessage(e.code);
    } on TimeoutException {
      SupaConfig.setOwnerToken(null);
      state = const AsyncData(null);
      return 'انتهت مهلة الاتصال، تحقق من الإنترنت وحاول مجدداً';
    } catch (_) {
      SupaConfig.setOwnerToken(null);
      state = const AsyncData(null);
      return 'خطأ في الاتصال، حاول مجددًا';
    }
  }

  // ── Biometric sign in (unlocks the stored, unexpired token) ──────────────

  Future<String?> signInWithBiometric() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedPhone = prefs.getString(_biometricPhoneKey);
    if (savedPhone == null || savedPhone.isEmpty) {
      return 'لا توجد بيانات بصمة محفوظة';
    }
    final villa = await _restoreFromStorage(prefs);
    if (villa == null) {
      return 'انتهت الجلسة، سجّل الدخول بكلمة المرور مرة واحدة';
    }
    state = AsyncData(villa);
    return null;
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _clearSession(prefs);
    SupaConfig.setOwnerToken(null);
    state = const AsyncData(null);
  }

  // ── Password management (verified server-side) ───────────────────────────

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final villa = state.asData?.value;
    if (villa == null) return 'لا توجد جلسة مستخدم';
    if (newPassword.trim().length < 4) return 'كلمة المرور الجديدة قصيرة جدًا';
    return _setPassword(villa, currentPassword.trim(), newPassword.trim());
  }

  Future<String?> setInitialPassword({required String newPassword}) async {
    final villa = state.asData?.value;
    if (villa == null) return 'لا توجد جلسة مستخدم';
    if (newPassword.trim().length < 4) return 'كلمة المرور الجديدة قصيرة جدًا';
    // First login: the server allows a set without a current password.
    return _setPassword(villa, '', newPassword.trim());
  }

  Future<String?> _setPassword(
      Villa villa, String current, String newPassword) async {
    if (!villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
      return 'الحساب غير مدعوم';
    }
    final ownerId = int.tryParse(
        villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
    if (ownerId == null) return 'الحساب غير صالح';
    final repo = ref.read(ownerAccountRepositoryProvider);
    try {
      await repo.setOwnPassword(current, newPassword);
      final updated = await repo.rebuildVillaById(ownerId);
      if (updated != null) {
        final prefs = await ref.read(sharedPreferencesProvider.future);
        // Refresh the cached owner profile (IsFirstLogin now false).
        final ownerJson = prefs.getString(_ownerMapKey);
        if (ownerJson != null) {
          try {
            final map = (json.decode(ownerJson) as Map).cast<String, dynamic>();
            map['IsFirstLogin'] = false;
            await prefs.setString(_ownerMapKey, json.encode(map));
          } catch (_) {/* keep old cache */}
        }
        state = AsyncData(updated);
      }
      return null;
    } catch (e) {
      return _passwordErrorMessage(e);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persistSession(
    SharedPreferences prefs,
    String token,
    Map<String, dynamic> owner,
    Villa villa,
  ) async {
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_ownerMapKey, json.encode(owner));
    await prefs.setString(_villaIdKey, villa.id);
    await prefs.setString(_villaPhoneKey, villa.phoneNumber);
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_ownerMapKey);
    await prefs.remove(_villaIdKey);
    await prefs.remove(_villaPhoneKey);
  }

  /// The exact `owner_id` claim (as text) from the JWT, or null.
  String? _ownerIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map;
      return payload['owner_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// True if the JWT has an `exp` at least 60s in the future.
  bool _tokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map;
      final exp = (payload['exp'] as num?)?.toInt();
      if (exp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp > now + 60;
    } catch (_) {
      return false;
    }
  }

  String _loginErrorMessage(String code) {
    switch (code) {
      case 'phone_not_found':
      case 'missing_credentials':
        return 'رقم الهاتف غير موجود في حسابات الملاك';
      case 'wrong_password':
        return 'كلمة المرور غير صحيحة';
      case 'network':
        return 'خطأ في الاتصال، تحقق من الإنترنت وحاول مجدداً';
      default:
        return 'تعذّر تسجيل الدخول، حاول مجددًا';
    }
  }

  String _passwordErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('wrong_password')) return 'كلمة المرور الحالية غير صحيحة';
    if (s.contains('weak_password')) return 'كلمة المرور الجديدة قصيرة جدًا';
    if (s.contains('not_owner')) return 'انتهت الجلسة، سجّل الدخول مجددًا';
    return 'تعذّر تغيير كلمة المرور، حاول مجددًا';
  }
}

// ── Derived providers ────────────────────────────────────────────────────────

final currentVillaProvider = Provider<Villa?>(
  (ref) => ref.watch(sessionControllerProvider).asData?.value,
);

final paymentsProvider = StreamProvider<List<Payment>>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return const Stream.empty();
  return ref.watch(paymentRepositoryProvider).watchByVilla(villa.id);
});

final serviceRequestsProvider = StreamProvider<List<ServiceRequest>>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return const Stream.empty();
  return ref
      .watch(serviceRequestRepositoryProvider)
      .watchByPhone(villa.phoneNumber);
});

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return const Stream.empty();
  return ref.watch(announcementRepositoryProvider).watchAll();
});

final settlementsProvider = StreamProvider<List<AnnualSettlement>>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return const Stream.empty();
  return ref
      .watch(annualSettlementRepositoryProvider)
      .watchByVilla(villa.id);
});

/// The account year the owner is currently viewing (defaults to this year).
class SelectedOwnerYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void set(int year) => state = year;
}

final selectedOwnerYearProvider =
    NotifierProvider<SelectedOwnerYearNotifier, int>(
        SelectedOwnerYearNotifier.new);

/// Years that have a published statement for the signed-in owner (newest first).
final ownerStatementYearsProvider = FutureProvider<List<int>>((ref) async {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return [DateTime.now().year];
  final repo = ref.watch(ownerAccountRepositoryProvider);
  if (villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
    final ownerId = int.tryParse(
        villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
    if (ownerId != null) return repo.availableStatementYears(ownerId);
  }
  return [DateTime.now().year];
});

/// Owner account with the precomputed balance for the selected year.
///
/// Rebuilds automatically whenever the owner's transactions or precomputed
/// statement change over realtime, so the balance stays live on every screen
/// (not only the one that happens to be mounted).
final ownerAccountProvider = FutureProvider<OwnerAccount?>((ref) async {
  ref.watch(ownerTransactionsStreamProvider);
  ref.watch(ownerStatementSignalProvider);
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return null;
  final year = ref.watch(selectedOwnerYearProvider);
  final repo = ref.watch(ownerAccountRepositoryProvider);
  if (villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
    final ownerId = int.tryParse(
        villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
    if (ownerId != null) return repo.fetchById(ownerId, year: year);
  }
  return repo.fetchByVillaNo(villa.villaNumber, year: year);
});

/// All ledger entries for the owner, sorted newest first (one-shot fetch).
final ownerTransactionsProvider =
    FutureProvider<List<OwnerLedgerEntry>>((ref) async {
  final account = await ref.watch(ownerAccountProvider.future);
  if (account == null) return const [];
  return ref.watch(ownerAccountRepositoryProvider).fetchTransactions(account.id);
});

/// Realtime signal that the owner's precomputed statement changed. The balance
/// comes from the statement, so screens invalidate [ownerAccountProvider] when
/// this fires (the ERP rebuilds the statement ~1.5s after a transaction).
final ownerStatementSignalProvider = StreamProvider<void>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null ||
      !villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
    return const Stream.empty();
  }
  final ownerId = int.tryParse(
      villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
  if (ownerId == null) return const Stream.empty();
  return ref.watch(ownerAccountRepositoryProvider).watchStatements(ownerId);
});

/// Real-time stream of owner transactions — used to detect new entries and
/// show push notifications while the app is in the foreground.
final ownerTransactionsStreamProvider =
    StreamProvider<List<OwnerLedgerEntry>>((ref) {
  final villa = ref.watch(currentVillaProvider);
  if (villa == null) return const Stream.empty();
  if (!villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
    return const Stream.empty();
  }
  final ownerId = int.tryParse(
      villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
  if (ownerId == null) return const Stream.empty();
  return ref.watch(ownerAccountRepositoryProvider).watchTransactions(ownerId);
});
