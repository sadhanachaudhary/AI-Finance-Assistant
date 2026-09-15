import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Primary card container with consistent styling, crisp light surface,
/// subtle border, configurable radius, padding, and tap support.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final Border? border;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 20,
    this.border,
    this.width,
    this.height,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ?? Border.all(color: AppTheme.borderLight, width: 1.2);
    final effectiveDecoration = BoxDecoration(
      color: color ?? AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: effectiveBorder,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
    );

    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: effectiveDecoration,
        clipBehavior: clipBehavior,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppTheme.primaryPurple.withValues(alpha: 0.08),
            highlightColor: AppTheme.primaryPurple.withValues(alpha: 0.04),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: effectiveDecoration,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Frosted Glass / Clean Elevated Gradient Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.gradientColors,
    this.borderColor,
    this.borderRadius = 22,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          Colors.white,
          const Color(0xFFF9FAFF),
        ];

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: borderColor ?? AppTheme.borderLight,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppTheme.primaryPurple.withValues(alpha: 0.08),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

/// Standardized section title header with optional icon, counter badge, and action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.badgeText,
    this.badgeColor,
    this.actionLabel,
    this.onActionTap,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? AppTheme.primaryPurple),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppTheme.primaryPurple).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (badgeColor ?? AppTheme.primaryPurple).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.primaryPurple),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standardized card with built-in header, icon, action, and child content.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
    this.badgeText,
    this.badgeColor,
    this.actionLabel,
    this.onActionTap,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            title: title,
            icon: icon,
            iconColor: iconColor,
            badgeText: badgeText,
            badgeColor: badgeColor,
            actionLabel: actionLabel,
            onActionTap: onActionTap,
            padding: const EdgeInsets.only(bottom: 14),
          ),
          child,
        ],
      ),
    );
  }
}

/// Standardized interactive tile / setting row with leading avatar icon, title,
/// subtitle, and trailing widget (Switch, Chip, or Chevron).
class ActionCardTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? cardColor;

  const ActionCardTile({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin,
      color: cardColor,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor ?? iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 22,
            ),
        ],
      ),
    );
  }
}
