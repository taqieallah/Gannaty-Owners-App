import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/app_text.dart';
import '../../features/notifications/providers/notification_history_provider.dart';
import '../../core/theme/app_theme.dart';
import 'owner_receipt_sheet.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  DateTime? _lastBackPressAt;

  // Track transaction IDs seen on first load â€” only notify about NEW ones.
  Set<int>? _seenTxIds;

  @override
  void initState() {
    super.initState();
    // Listen for new owner transactions and show a local notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(ownerTransactionsStreamProvider, (prev, next) {
        final entries = next.asData?.value;
        if (entries == null) return;

        final currentIds = entries.map((e) => e.id).toSet();

        if (_seenTxIds == null) {
          // First emission - just record what we have, don't notify.
          _seenTxIds = currentIds;
          ref.invalidate(ownerAccountProvider);
          ref.invalidate(ownerTransactionsProvider);
          return;
        }

        final previousIds = _seenTxIds!;
        final hasAnyChange = currentIds.length != previousIds.length ||
            !currentIds.containsAll(previousIds);

        if (hasAnyChange) {
          ref.invalidate(ownerAccountProvider);
          ref.invalidate(ownerTransactionsProvider);
        }

        final newEntries =
            entries.where((e) => !previousIds.contains(e.id)).toList();
        _seenTxIds = currentIds;

        for (final entry in newEntries) {
          _handleNewTransaction(entry);
        }
      });
    });
  }

  void _handleNewTransaction(OwnerLedgerEntry entry) {
    final villa = ref.read(currentVillaProvider);
    final ownerName = villa?.ownerName ?? '';
    final villaNo = villa?.villaNumber ?? '';

    final isPayment = entry.isPayment;
    final amountStr = entry.amount.toStringAsFixed(0);

    // Show local notification.
    NotificationService.showSimpleNotification(
      title: isPayment ? 'تم تسجيل دفعة' : 'رسوم جديدة',
      body: isPayment
          ? 'تم استلام $amountStr جنيه - اضغط لعرض الإيصال'
          : 'تمت إضافة رسوم بقيمة $amountStr جنيه',
    );

    // Refresh balance card and transaction list automatically.
    ref.invalidate(ownerAccountProvider);
    ref.invalidate(ownerTransactionsProvider);

    // Defer the sheet to the next frame to avoid build-phase conflicts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      OwnerReceiptSheet.show(
        context,
        entry: entry,
        ownerName: ownerName,
        villaNo: villaNo,
      );
    });
  }

  bool _isRootShellRoute(String location) {
    return location == '/home' ||
        location == '/balance' ||
        location == '/payments' ||
        location == '/requests' ||
        location == '/announcements' ||
        location == '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);
    final location = GoRouterState.of(context).matchedLocation;
    final notifHistory =
        ref.watch(notificationHistoryProvider).asData?.value ?? [];
    final isRootShellRoute = _isRootShellRoute(location);

    final index = location.startsWith('/profile')
        ? 4
        : location.startsWith('/announcements')
            ? 3
            : location.startsWith('/requests')
                ? 2
                : location.startsWith('/payments')
                    ? 1
                    : 0;

    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF140D09)
        : const Color(0xFFF7F1E3);

    return PopScope(
      canPop: !isRootShellRoute,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !isRootShellRoute) return;

        if (location != '/home') {
          context.go('/home');
          return;
        }

        final now = DateTime.now();
        final shouldExit = _lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) < const Duration(seconds: 2);
        if (shouldExit) {
          await SystemNavigator.pop();
          return;
        }

        _lastBackPressAt = now;
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                settings.isArabic
                    ? 'اضغط مرة أخرى لإغلاق التطبيق'
                    : 'Press back again to close the app',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: Scaffold(
        body: widget.child,
        backgroundColor: bg,
        floatingActionButton: FloatingActionButton.small(
          heroTag: 'notification_fab',
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 2,
          onPressed: () => context.push('/notifications'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded),
              if (notifHistory.isNotEmpty)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notifHistory.length > 9 ? '9+' : '${notifHistory.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      label: t.home,
                      icon: Icons.home_rounded,
                      selected: index == 0,
                      onTap: () => context.go('/home'),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: t.payments,
                      icon: Icons.receipt_long_rounded,
                      selected: index == 1,
                      onTap: () => context.go('/payments'),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: t.requests,
                      icon: Icons.handyman_rounded,
                      selected: index == 2,
                      onTap: () => context.go('/requests'),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: t.announcements,
                      icon: Icons.campaign_rounded,
                      selected: index == 3,
                      onTap: () => context.go('/announcements'),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: t.profile,
                      icon: Icons.person_rounded,
                      selected: index == 4,
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).textTheme.bodySmall?.color;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

