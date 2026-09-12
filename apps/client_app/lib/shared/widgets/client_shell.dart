import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/settings/app_settings.dart';
import 'desktop_sidebar.dart';
import '../../core/settings/app_text.dart';
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

    final cs = Theme.of(context).colorScheme;

    // ── Desktop / tablet: cream page → white workspace → dark sidebar ────────
    if (isWide(context)) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.xl,
              border: Border.all(color: AppColors.lineCream),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(children: [
              DesktopSidebar(location: location),
              const VerticalDivider(width: 1, color: AppColors.line),
              Expanded(
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(scaffoldBackgroundColor: AppColors.surface),
                  child: widget.child,
                ),
              ),
            ]),
          ),
        ),
      );
    }

    // ── Mobile: bottom navigation ────────────────────────────────────────────
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outline)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  Expanded(child: _NavItem(label: t.home, icon: Icons.home_rounded, selected: index == 0, onTap: () => context.go('/home'))),
                  Expanded(child: _NavItem(label: t.payments, icon: Icons.account_balance_wallet_rounded, selected: index == 1, onTap: () => context.go('/payments'))),
                  Expanded(child: _NavItem(label: t.requests, icon: Icons.build_rounded, selected: index == 2, onTap: () => context.go('/requests'))),
                  Expanded(child: _NavItem(label: t.announcements, icon: Icons.campaign_rounded, selected: index == 3, onTap: () => context.go('/announcements'))),
                  Expanded(child: _NavItem(label: t.profile, icon: Icons.person_rounded, selected: index == 4, onTap: () => context.go('/profile'))),
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
    const active = AppColors.copper;
    final inactive = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = selected ? active : inactive;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: selected ? 22 : 0,
            decoration: const BoxDecoration(
              color: active,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
            ),
          ),
          const SizedBox(height: 7),
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color),
          ),
        ],
      ),
    );
  }
}

