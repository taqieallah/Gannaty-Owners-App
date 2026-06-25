import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/villas/screens/villas_list_screen.dart';
import '../../features/villas/screens/add_villa_screen.dart';
import '../../features/villas/screens/edit_villa_screen.dart';
import '../../features/villas/screens/villa_detail_screen.dart';
import '../../features/villas/screens/import_villas_screen.dart';
import '../../features/payments/screens/payments_list_screen.dart';
import '../../features/payments/screens/add_payment_screen.dart';
import '../../features/payments/screens/import_excel_screen.dart';
import '../../features/service_requests/screens/requests_list_screen.dart';
import '../../features/service_requests/screens/request_detail_screen.dart';
import '../../features/settlements/screens/annual_settlement_screen.dart';
import '../../features/settlements/screens/annual_settings_screen.dart';
import '../../features/settlements/screens/set_opening_balance_screen.dart';

// Used by main.dart to navigate when a notification is tapped
String adminInitialNotificationRoute = '/dashboard';
final _navigatorKey = GlobalKey<NavigatorState>();

void navigateFromAdminNotification(String route) {
  final context = _navigatorKey.currentContext;
  if (context != null) context.go(route);
}

/// Slide-in from right (used for push/detail pages)
CustomTransitionPage<void> _slidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

/// Fade (used for main nav tab transitions)
CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: adminInitialNotificationRoute,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isOnLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const DashboardScreen()),
      ),
      GoRoute(
        path: '/villas',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const VillasListScreen()),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) =>
                _slidePage(key: state.pageKey, child: const AddVillaScreen()),
          ),
          GoRoute(
            path: 'import',
            pageBuilder: (context, state) => _slidePage(
                key: state.pageKey, child: const ImportVillasScreen()),
          ),
          GoRoute(
            path: ':villaId',
            pageBuilder: (context, state) => _slidePage(
              key: state.pageKey,
              child: VillaDetailScreen(
                  villaId: state.pathParameters['villaId']!),
            ),
          ),
          GoRoute(
            path: ':villaId/edit',
            pageBuilder: (context, state) => _slidePage(
              key: state.pageKey,
              child: EditVillaScreen(
                  villaId: state.pathParameters['villaId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/payments',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const PaymentsListScreen()),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) => _slidePage(
                key: state.pageKey, child: const AddPaymentScreen()),
          ),
          GoRoute(
            path: 'import',
            pageBuilder: (context, state) => _slidePage(
                key: state.pageKey, child: const ImportExcelScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/requests',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey, child: const RequestsListScreen()),
        routes: [
          GoRoute(
            path: ':requestId',
            pageBuilder: (context, state) => _slidePage(
              key: state.pageKey,
              child: RequestDetailScreen(
                  requestId: state.pathParameters['requestId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settlements',
        pageBuilder: (context, state) => _fadePage(
            key: state.pageKey,
            child: const AnnualSettlementScreen()),
        routes: [
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) => _slidePage(
                key: state.pageKey,
                child: const AnnualSettingsScreen()),
          ),
          GoRoute(
            path: 'opening-balance',
            pageBuilder: (context, state) => _slidePage(
                key: state.pageKey,
                child: const SetOpeningBalanceScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
