import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width = double.infinity,
    this.height = 54,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    if (variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: isEnabled ? onPressed : null,
        child: _buildContent(textColor ?? AppTheme.primaryPurple),
      );
    }

    if (variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isEnabled
                  ? (backgroundColor ?? AppTheme.primaryPurple)
                  : AppTheme.borderLight,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _buildContent(textColor ?? AppTheme.primaryPurple),
        ),
      );
    }

    // Primary & Secondary
    final isPrimary = variant == AppButtonVariant.primary;
    final defaultBg = isPrimary ? AppTheme.primaryPurple : AppTheme.surfaceElevated;
    final effectiveBg = backgroundColor ?? defaultBg;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPrimary && isEnabled && backgroundColor == null
              ? const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary && backgroundColor == null
                ? Colors.transparent
                : (isEnabled ? effectiveBg : const Color(0xFFE2E8F0)),
            shadowColor: Colors.transparent,
            foregroundColor: textColor ?? (isPrimary ? Colors.white : AppTheme.textPrimary),
            disabledBackgroundColor: const Color(0xFFF1F5F9),
            disabledForegroundColor: AppTheme.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: _buildContent(textColor ?? (isPrimary ? Colors.white : AppTheme.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildContent(Color contentColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: contentColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: contentColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: contentColor,
        letterSpacing: 0.1,
      ),
    );
  }
}
