import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../utils/error_mapper.dart';
import 'app_button.dart';

class AppLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const AppLoading({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryPurple,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String? message;
  final String? title;
  final String? tip;
  final dynamic error;
  final VoidCallback? onRetry;
  final String retryText;

  const AppErrorView({
    super.key,
    this.message,
    this.title,
    this.tip,
    this.error,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    String displayTitle = title ?? 'Unable to Load';
    String displayMessage = message ?? 'An unexpected error occurred.';
    String? displayTip = tip;
    bool isNetwork = false;

    if (error != null) {
      final friendly = ErrorMapper.map(error);
      displayTitle = title ?? friendly.title;
      displayMessage = message ?? friendly.message;
      displayTip = tip ?? friendly.tip;
      isNetwork = friendly.isNetworkIssue;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isNetwork ? const Color(0xFFF59E0B) : AppTheme.outflowCoral).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isNetwork ? const Color(0xFFF59E0B) : AppTheme.outflowCoral).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                color: isNetwork ? const Color(0xFFF59E0B) : AppTheme.outflowCoral,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (displayTip != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTheme.primaryPurple),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayTip,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              AppButton(
                text: retryText,
                onPressed: onRetry,
                width: 160,
                height: 44,
                variant: AppButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.receipt_long_outlined,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.softPurpleBadge,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryPurple,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 22),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                width: 180,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
