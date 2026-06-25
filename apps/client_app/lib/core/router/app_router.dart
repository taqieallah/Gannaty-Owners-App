import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/set_password_screen.dart';
import '../../features/balance/screens/balance_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notification_history_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/service_requests/screens/my_requests_screen.dart';
import '../../features/service_requests/screens/request_detail_screen.dart';
import '../../features/service_requests/screens/submit_request_screen.dart';
import '../../shared/widgets/client_shell.dart';
import '../providers/app_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: RouterRefreshScope(ref),
    redirect: (context, state) {
      final villa = session.asData?.value;
      final onLogin = state.matchedLocation == '/login';
      final onSetPassword = state.matchedLocation == '/set-password';
      final requiresPasswordReset = villa != null &&
          (villa.isFirstLogin || villa.password.trim() == '123456');

      if (session.isLoading) {
        return onLogin ? null : '/login';
      }

      if (villa == null) {
        return onLogin ? null : '/login';
      }

      if (requiresPasswordReset) {
        return onSetPassword ? null : '/set-password';
      }

      if (onLogin || onSetPassword) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationHistoryScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/balance',
            builder: (context, state) => const BalanceScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/requests',
            builder: (context, state) => const MyRequestsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const SubmitRequestScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => RequestDetailScreen(
                  requestId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class RouterRefreshScope extends ChangeNotifier {
  RouterRefreshScope(this.ref) {
    ref.listen(sessionControllerProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
}
