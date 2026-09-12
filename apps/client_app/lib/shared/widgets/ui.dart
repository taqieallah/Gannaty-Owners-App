import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_type.dart';

// ── Formatting ──────────────────────────────────────────────────────────────
final _egp = NumberFormat('#,##0.##', 'en');
String money(num v) => _egp.format(v);

// ── Surface ─────────────────────────────────────────────────────────────────
/// A flat, bordered surface. The default building block — no heavy shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.onTap,
    this.color,
    this.border = true,
    this.radius = Radii.md,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool border;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: radius,
        border: border ? Border.all(color: cs.outline) : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md, top: Gap.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: Radii.pill,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(actionLabel!,
                    style: AppType.eyebrow(AppColors.copper)),
              ),
            ),
        ],
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppType.eyebrow(color ?? Theme.of(context).colorScheme.onSurfaceVariant));
}

// ── Status badge ──────────────────────────────────────────────────────────────
enum BadgeTone { success, danger, amber, info, neutral, copper }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral, this.icon});
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pill),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), Gap.w4],
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  static (Color, Color) _tone(BadgeTone t) => switch (t) {
        BadgeTone.success => (AppColors.success, AppColors.successTint),
        BadgeTone.danger => (AppColors.danger, AppColors.dangerTint),
        BadgeTone.amber => (const Color(0xFF8A6410), AppColors.amberTint),
        BadgeTone.info => (AppColors.info, AppColors.infoTint),
        BadgeTone.copper => (AppColors.copper, AppColors.copperTint),
        BadgeTone.neutral => (AppColors.inkSoft, AppColors.neutralTint),
      };
}

// ── KPI stat card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = BadgeTone.neutral,
    this.valueColor,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData? icon;
  final BadgeTone tone;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (fg, bg) = StatusBadge._tone(tone);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: bg, borderRadius: Radii.sm),
              child: Icon(icon, size: 18, color: fg),
            ),
            Gap.h12,
          ],
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.num(valueColor ?? AppColors.ink, size: 20, weight: FontWeight.w800)),
          Gap.h4,
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}

// ── Quick action ──────────────────────────────────────────────────────────────
class QuickAction extends StatelessWidget {
  const QuickAction(
      {super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: Gap.lg, horizontal: Gap.sm),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
              color: AppColors.copperTint, borderRadius: Radii.md),
          child: Icon(icon, color: AppColors.copper, size: 22),
        ),
        Gap.h8,
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelLarge?.copyWith(fontSize: 12.5)),
      ]),
    );
  }
}

// ── States ──────────────────────────────────────────────────────────────────
class AppEmpty extends StatelessWidget {
  const AppEmpty(
      {super.key,
      required this.icon,
      required this.title,
      this.message,
      this.actionLabel,
      this.onAction});
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
                color: AppColors.neutralTint, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: AppColors.inkSoft),
          ),
          Gap.h16,
          Text(title,
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (message != null) ...[
            Gap.h8,
            Text(message!, textAlign: TextAlign.center, style: t.bodySmall),
          ],
          if (actionLabel != null) ...[
            Gap.h20,
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(Gap.huge),
          child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6)),
        ),
      );
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => AppEmpty(
        icon: Icons.error_outline_rounded,
        title: 'حدث خطأ',
        message: message,
        actionLabel: onRetry == null ? null : 'إعادة المحاولة',
        onAction: onRetry,
      );
}

// ── Layout helper ─────────────────────────────────────────────────────────────
/// Centers and constrains page content on wide screens.
class ContentBound extends StatelessWidget {
  const ContentBound({super.key, required this.child, this.maxWidth = kContentMaxWidth});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
