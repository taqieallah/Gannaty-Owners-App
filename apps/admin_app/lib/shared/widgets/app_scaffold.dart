import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/app_settings_provider.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBottomNav;
  final Widget? bottomSheet;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showBottomNav = true,
    this.bottomSheet,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navIndex(location);
    final settings = ref.watch(appSettingsProvider);
    final l10n = ref.watch(l10nProvider);
    final colors = context.appColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: colors.bg,
        systemNavigationBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          title: Text(title, style: AppTextStyles.appBar),
          actions: [
            ...?actions,
            // Settings popup
            _SettingsButton(settings: settings, l10n: l10n, ref: ref),
          ],
          bottom: bottom,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomSheet: bottomSheet,
        bottomNavigationBar: showBottomNav
            ? _AdminBottomNav(
                currentIndex: currentIndex, colors: colors, l10n: l10n)
            : null,
      ),
    );
  }

  int _navIndex(String location) {
    if (location.startsWith('/villas')) return 1;
    if (location.startsWith('/payments')) return 2;
    if (location.startsWith('/requests')) return 3;
    if (location.startsWith('/settlements')) return 4;
    return 0;
  }
}

// ── Settings Popup Button ─────────────────────────────────────────────────────

class _SettingsButton extends StatelessWidget {
  final AppSettings settings;
  final AppL10n l10n;
  final WidgetRef ref;

  const _SettingsButton(
      {required this.settings, required this.l10n, required this.ref});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.tune_rounded, color: Colors.white),
      color: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'theme') {
          ref.read(appSettingsProvider.notifier).toggleTheme();
        } else if (v == 'lang') {
          ref.read(appSettingsProvider.notifier).toggleLanguage();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(children: [
            Icon(
              settings.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: AppColors.navy,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              settings.isDark ? 'Light Mode' : l10n.darkMode,
              style: AppTextStyles.body.copyWith(
                  color: context.appColors.textPrimary),
            ),
          ]),
        ),
        PopupMenuItem(
          value: 'lang',
          child: Row(children: [
            Icon(Icons.language_rounded, color: AppColors.navy, size: 20),
            const SizedBox(width: 10),
            Text(
              settings.isArabic ? 'English' : 'عربي',
              style: AppTextStyles.body.copyWith(
                  color: context.appColors.textPrimary),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Admin Bottom Navigation ───────────────────────────────────────────────────

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final AppColorScheme colors;
  final AppL10n l10n;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l10n.navDashboard, '/dashboard'),
      (Icons.villa_outlined, Icons.villa_rounded, l10n.navVillas, '/villas'),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.navPayments, '/payments'),
      (Icons.build_outlined, Icons.build_rounded, l10n.navRequests, '/requests'),
      (Icons.calculate_outlined, Icons.calculate_rounded, l10n.navSettlements, '/settlements'),
    ];

    return Container(
      color: colors.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final (icon, activeIcon, label, route) = items[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: _NavButton(
                    icon: icon,
                    activeIcon: activeIcon,
                    label: label,
                    selected: selected,
                    colors: colors,
                    onTap: () => context.go(route),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.selected ? 18 : 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: widget.selected
                    ? widget.colors.navyLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedScale(
                scale: widget.selected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    widget.selected ? widget.activeIcon : widget.icon,
                    key: ValueKey(widget.selected),
                    color: widget.selected
                        ? AppColors.navy
                        : widget.colors.textHint,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w400,
                color: widget.selected ? AppColors.navy : widget.colors.textHint,
                height: 1.2,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
