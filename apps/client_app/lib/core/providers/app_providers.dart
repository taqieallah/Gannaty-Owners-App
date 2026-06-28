import 'dart:async';

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

class SessionController extends AsyncNotifier<Villa?> {
  static const _villaIdKey = 'client_villa_id';
  static const _villaPhoneKey = 'client_villa_phone';

  // ── Session restore ──────────────────────────────────────────────────────

  @override
  Future<Villa?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final auth = ref.watch(authServiceProvider);

    if (auth.currentUser == null) {
      await prefs.remove(_villaIdKey);
      await prefs.remove(_villaPhoneKey);
      return null;
    }

    final savedId = prefs.getString(_villaIdKey);

    // ── Owner-based session (I:\Rebrand حسابات الملاك) ──────────────────
    if (savedId != null &&
        savedId.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
      final ownerId =
          int.tryParse(savedId.substring(OwnerAccountRepository.ownerIdPrefix.length));
      if (ownerId != null) {
        await _ensureExpensesAuth();
        final ownerRepo = ref.read(ownerAccountRepositoryProvider);
        final villa = await ownerRepo.rebuildVillaById(ownerId);
        if (villa != null) return villa;
      }
    }

    // ── No valid session found ───────────────────────────────────────────
    await prefs.remove(_villaIdKey);
    await prefs.remove(_villaPhoneKey);
    return null;
  }

  // ── Expenses Firebase auth ───────────────────────────────────────────────

  /// Ensures the client has an anonymous Supabase session so RLS allows the
  /// owner reads (mirrors the old anonymous Firebase auth).
  static Future<void> _ensureExpensesAuth() async {
    try {
      final auth = SupaConfig.client.auth;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (_) {
      // Non-critical — a failed read will surface as a user-visible error.
    }
  }

  /// Push notifications are deferred on the Supabase build.
  static Future<void> _saveFcmToken(String ownerDocId, int ownerId) async {}

  // ── Sign in ──────────────────────────────────────────────────────────────

  Future<String?> signIn({
    required String phone,
    required String password,
  }) async {
    final auth = ref.read(authServiceProvider);
    final prefs = await ref.read(sharedPreferencesProvider.future);

    await prefs.remove(_villaIdKey);
    await prefs.remove(_villaPhoneKey);

    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    // Also authenticate on the expenses secondary app so Firestore rules pass.
    await _ensureExpensesAuth();

    // ── Lookup in حسابات الملاك (owners collection) ──────────────────────
    final ownerRepo = ref.read(ownerAccountRepositoryProvider);
    try {
      final ownerDoc =
          await ownerRepo.findOwnerDocByPhone(phone.trim()).timeout(
                const Duration(seconds: 15),
              );
      if (ownerDoc == null) {
        state = const AsyncData(null);
        return 'رقم الهاتف غير موجود في حسابات الملاك';
      }
      final villa = OwnerAccountRepository.buildVillaFromDoc(ownerDoc);
      if (villa.password.trim() != password.trim()) {
        state = const AsyncData(null);
        return 'كلمة المرور غير صحيحة';
      }
      await prefs.setString(_villaIdKey, villa.id);
      await prefs.setString(_villaPhoneKey, villa.phoneNumber);
      state = AsyncData(villa);
      // Save FCM token so admin can send push notifications to this device.
      unawaited(_saveFcmToken(
        ownerDoc.id,
        int.tryParse(villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length)) ?? 0,
      ));
      return null;
    } on TimeoutException {
      state = const AsyncData(null);
      return 'انتهت مهلة الاتصال، تحقق من الإنترنت وحاول مجدداً';
    } catch (e) {
      state = const AsyncData(null);
      return 'خطأ في الاتصال: ${e.toString()}';
    }
  }

  // ── Biometric sign in ────────────────────────────────────────────────────

  Future<String?> signInWithBiometric() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedPhone = prefs.getString('biometric_phone');
    if (savedPhone == null || savedPhone.isEmpty) {
      return 'لا توجد بيانات بصمة محفوظة';
    }

    final auth = ref.read(authServiceProvider);
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    await _ensureExpensesAuth();

    final ownerRepo = ref.read(ownerAccountRepositoryProvider);
    final ownerDoc = await ownerRepo.findOwnerDocByPhone(savedPhone.trim());
    if (ownerDoc == null) return 'رقم الهاتف غير موجود في حسابات الملاك';

    final villa = OwnerAccountRepository.buildVillaFromDoc(ownerDoc);
    await prefs.setString(_villaIdKey, villa.id);
    await prefs.setString(_villaPhoneKey, villa.phoneNumber);
    state = AsyncData(villa);
    return null;
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final auth = ref.read(authServiceProvider);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_villaIdKey);
    await prefs.remove(_villaPhoneKey);
    if (auth.currentUser != null) {
      await auth.signOut();
    }
    state = const AsyncData(null);
  }

  // ── Password management ──────────────────────────────────────────────────

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final villa = state.asData?.value;
    if (villa == null) return 'لا توجد جلسة مستخدم';
    if (villa.password.trim() != currentPassword.trim()) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (newPassword.trim().length < 4) {
      return 'كلمة المرور الجديدة قصيرة جدًا';
    }
    return _doUpdatePassword(villa, newPassword.trim());
  }

  Future<String?> setInitialPassword({required String newPassword}) async {
    final villa = state.asData?.value;
    if (villa == null) return 'لا توجد جلسة مستخدم';
    if (newPassword.trim().length < 4) {
      return 'كلمة المرور الجديدة قصيرة جدًا';
    }
    return _doUpdatePassword(villa, newPassword.trim());
  }

  Future<String?> _doUpdatePassword(Villa villa, String newPassword) async {
    if (villa.id.startsWith(OwnerAccountRepository.ownerIdPrefix)) {
      // Owner-based session → update owners collection
      final ownerId = int.parse(
          villa.id.substring(OwnerAccountRepository.ownerIdPrefix.length));
      await ref
          .read(ownerAccountRepositoryProvider)
          .updatePassword(ownerId, newPassword);
      final updated = await ref
          .read(ownerAccountRepositoryProvider)
          .rebuildVillaById(ownerId);
      state = AsyncData(updated);
    } else {
      // Legacy villas session → update villas collection
      await ref
          .read(villaRepositoryProvider)
          .updatePassword(villa.id, newPassword);
      final updated =
          await ref.read(villaRepositoryProvider).getById(villa.id);
      state = AsyncData(updated);
    }
    return null;
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
/// If the session is owner-based (id starts with "owner_") → fetches by ID directly.
/// Otherwise falls back to VillaNo lookup for legacy villas-collection sessions.
final ownerAccountProvider = FutureProvider<OwnerAccount?>((ref) async {
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
