import 'package:flutter/material.dart';
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
              color ?? const Color(0xFF6C63FF),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white60,
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
                color: (isNetwork ? const Color(0xFFF59E0B) : const Color(0xFFFB7185)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isNetwork ? const Color(0xFFF59E0B) : const Color(0xFFFB7185)).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                color: isNetwork ? const Color(0xFFF59E0B) : const Color(0xFFFB7185),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (displayTip != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayTip,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
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
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C2C2C), width: 1.5),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6C63FF),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white54,
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
