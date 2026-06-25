// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GDS BUTTON
// ─────────────────────────────────────────────────────────────────────────────

enum GdsButtonVariant { primary, secondary, ghost, danger, success }

class GdsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GdsButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double height;

  const GdsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GdsButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = _bgColor(colors);
    final fg = _fgColor;
    final border = _borderColor(colors);
    final disabled = onPressed == null && !loading;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppRadius.mdRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: disabled ? colors.border : bg,
              borderRadius: AppRadius.mdRadius,
              border: border != null
                  ? Border.all(color: border, width: 1.5)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize:
                    fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: AppTextStyles.titleSm.copyWith(color: fg)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _bgColor(AppColorScheme c) {
    switch (variant) {
      case GdsButtonVariant.primary:   return AppColors.navy;
      case GdsButtonVariant.secondary: return c.surface;
      case GdsButtonVariant.ghost:     return Colors.transparent;
      case GdsButtonVariant.danger:    return AppColors.error;
      case GdsButtonVariant.success:   return AppColors.success;
    }
  }

  Color get _fgColor {
    switch (variant) {
      case GdsButtonVariant.primary:   return Colors.white;
      case GdsButtonVariant.secondary: return AppColors.navy;
      case GdsButtonVariant.ghost:     return AppColors.navy;
      case GdsButtonVariant.danger:    return Colors.white;
      case GdsButtonVariant.success:   return Colors.white;
    }
  }

  Color? _borderColor(AppColorScheme c) {
    if (variant == GdsButtonVariant.secondary) return AppColors.navy;
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS CARD
// ─────────────────────────────────────────────────────────────────────────────

class GdsCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool highlighted;

  const GdsCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = color ?? colors.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgRadius,
        border: Border(
          left: highlighted
              ? const BorderSide(color: AppColors.navy, width: 3)
              : BorderSide(color: colors.border),
          top: BorderSide(color: colors.border),
          right: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              borderRadius: AppRadius.lgRadius,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.lgRadius,
                child: Padding(
                  padding: padding ?? AppSpacing.cardPadding,
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? AppSpacing.cardPadding,
              child: child,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class GdsStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const GdsStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GdsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.numberLg.copyWith(
                  color: color, fontSize: 26)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                  color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}

class GdsStatCardSkeleton extends StatelessWidget {
  const GdsStatCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return GdsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GdsShimmer(width: 40, height: 40, radius: AppRadius.sm),
          const SizedBox(height: 12),
          GdsShimmer(width: 60, height: 28),
          const SizedBox(height: 4),
          GdsShimmer(width: 90, height: 13),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

enum GdsChipVariant { paid, pending, overdue, inProgress, settled, manual }

class GdsStatusChip extends StatelessWidget {
  final GdsChipVariant variant;
  final String? label;

  const GdsStatusChip({super.key, required this.variant, this.label});

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: config.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? config.label,
            style: AppTextStyles.chip.copyWith(color: config.text),
          ),
        ],
      ),
    );
  }

  _ChipConfig get _config {
    switch (variant) {
      case GdsChipVariant.paid:
        return _ChipConfig(bg: AppColors.successLight, border: AppColors.successBorder, dot: AppColors.success, text: AppColors.success, label: 'مدفوع');
      case GdsChipVariant.pending:
        return _ChipConfig(bg: AppColors.warningLight, border: AppColors.warningBorder, dot: AppColors.warning, text: AppColors.warning, label: 'معلق');
      case GdsChipVariant.overdue:
        return _ChipConfig(bg: AppColors.errorLight, border: AppColors.errorBorder, dot: AppColors.error, text: AppColors.error, label: 'متأخر');
      case GdsChipVariant.inProgress:
        return _ChipConfig(bg: AppColors.infoLight, border: AppColors.infoBorder, dot: AppColors.info, text: AppColors.info, label: 'قيد التنفيذ');
      case GdsChipVariant.settled:
        return _ChipConfig(bg: AppColors.successLight, border: AppColors.successBorder, dot: AppColors.success, text: AppColors.success, label: 'تمت التسوية');
      case GdsChipVariant.manual:
        return _ChipConfig(bg: const Color(0xFFE8EDF6), border: const Color(0xFFE8EDF6), dot: AppColors.navyMid, text: AppColors.navyMid, label: 'يدوي');
    }
  }
}

class _ChipConfig {
  final Color bg, border, dot, text;
  final String label;
  const _ChipConfig({required this.bg, required this.border, required this.dot, required this.text, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class GdsSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const GdsSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: AppTextStyles.titleSm.copyWith(
                  color: context.appColors.textPrimary)),
        ),
        if (trailing != null) trailing!,
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: AppTextStyles.label.copyWith(color: AppColors.navy)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class GdsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GdsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.navyPale,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: colors.textHint),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTextStyles.title.copyWith(color: colors.textPrimary),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: GdsButton(
                    label: actionLabel!, onPressed: onAction, fullWidth: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS INFO ROW
// ─────────────────────────────────────────────────────────────────────────────

class GdsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const GdsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
          const Spacer(),
          Text(value,
              style: (bold ? AppTextStyles.titleSm : AppTextStyles.bodySm)
                  .copyWith(color: valueColor ?? colors.textPrimary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS LOADING
// ─────────────────────────────────────────────────────────────────────────────

class GdsLoading extends StatelessWidget {
  const GdsLoading({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class GdsShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const GdsShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  State<GdsShimmer> createState() => _GdsShimmerState();
}

class _GdsShimmerState extends State<GdsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.appColors.border;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS BALANCE CARD (hero financial display)
// ─────────────────────────────────────────────────────────────────────────────

class GdsBalanceCard extends StatelessWidget {
  final String amount;
  final String label;
  final String subtitle;

  const GdsBalanceCard({
    super.key,
    required this.amount,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.label
                  .copyWith(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 10),
          Text(amount,
              style: AppTextStyles.numberXl.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: AppTextStyles.bodySm
                  .copyWith(color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GDS SETTINGS TILE (for dark mode / language toggles)
// ─────────────────────────────────────────────────────────────────────────────

class GdsSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const GdsSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GdsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.navyPale,
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, color: AppColors.navy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTextStyles.titleSm
                    .copyWith(color: colors.textPrimary)),
          ),
          trailing,
        ],
      ),
    );
  }
}
