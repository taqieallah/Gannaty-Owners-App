import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_type.dart';
import '../../core/providers/app_providers.dart';

/// The dark navigation sidebar for tablet/desktop widths — deep navy, copper
/// active state, brand mark at the top, settings/logout pinned to the bottom.
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key, required this.location});
  final String location;

  static const _items = [
    (Icons.grid_view_rounded, 'الرئيسية', '/home'),
    (Icons.account_balance_wallet_rounded, 'المدفوعات', '/payments'),
    (Icons.build_rounded, 'طلبات الصيانة', '/requests'),
    (Icons.campaign_rounded, 'الإعلانات', '/announcements'),
    (Icons.notifications_none_rounded, 'الإشعارات', '/notifications'),
    (Icons.person_outline_rounded, 'الملف الشخصي', '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    return Container(
      width: 268,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xxl, Gap.xl, Gap.xl),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.copper, borderRadius: Radii.md),
                child: const Icon(Icons.holiday_village_rounded,
                    color: Colors.white, size: 22),
              ),
              Gap.w12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كمبوند جنتي',
                      style: AppType.num(Colors.white, size: 15.5, weight: FontWeight.w800)),
                  Text('اتحاد الشاغلين',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11.5)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 4),
          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              children: [
                for (final (icon, label, path) in _items)
                  _SideItem(
                    icon: icon,
                    label: label,
                    selected: location.startsWith(path),
                    onTap: () => path == '/notifications'
                        ? context.push(path)
                        : context.go(path),
                  ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(children: [
              _SideItem(
                icon: Icons.logout_rounded,
                label: 'تسجيل الخروج',
                selected: false,
                danger: true,
                onTap: () =>
                    ref.read(sessionControllerProvider.notifier).signOut(),
              ),
              Gap.h8,
              Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(
                    (villa?.ownerName.trim().isNotEmpty ?? false)
                        ? villa!.ownerName.trim().characters.first
                        : '؟',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(villa?.ownerName ?? 'مالك',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      Text('فيلا ${villa?.villaNumber ?? '—'}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      this.danger = false});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final base = danger
        ? const Color(0xFFE88A8A)
        : Colors.white.withValues(alpha: 0.66);
    final color = selected ? Colors.white : base;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.copper : Colors.transparent,
        borderRadius: Radii.md,
        child: InkWell(
          borderRadius: Radii.md,
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 11),
            child: Row(children: [
              Icon(icon, size: 20, color: color),
              Gap.w12,
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}
