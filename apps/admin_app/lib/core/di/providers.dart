import 'package:compound_core/compound_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Core services ───────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final villaRepositoryProvider =
    Provider<VillaRepository>((ref) => VillaRepository());

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => PaymentRepository());

final serviceRequestRepositoryProvider =
    Provider<ServiceRequestRepository>((ref) => ServiceRequestRepository());

// ── Auth state ───────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Villa streams ────────────────────────────────────────────────────────────

final villasProvider = StreamProvider<List<Villa>>((ref) {
  return ref.watch(villaRepositoryProvider).watchAll();
});

// ── Payment streams ──────────────────────────────────────────────────────────

final allPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchAll();
});

// ── Service request streams ──────────────────────────────────────────────────

final allRequestsProvider = StreamProvider<List<ServiceRequest>>((ref) {
  return ref.watch(serviceRequestRepositoryProvider).watchAll();
});

// ── Annual settings & settlements ─────────────────────────────────────────────

final annualSettingsRepositoryProvider =
    Provider<AnnualSettingsRepository>((ref) => AnnualSettingsRepository());

final annualSettlementRepositoryProvider =
    Provider<AnnualSettlementRepository>((ref) => AnnualSettlementRepository());

final annualSettingsProvider =
    StreamProvider.family<AnnualSettings?, int>((ref, year) {
  return ref.watch(annualSettingsRepositoryProvider).watch(year);
});

final allSettlementsProvider = StreamProvider<List<AnnualSettlement>>((ref) {
  return ref.watch(annualSettlementRepositoryProvider).watchAll();
});
