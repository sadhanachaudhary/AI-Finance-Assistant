import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final IconData icon;
  final Color accentColor;
  final double? trendPercent;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    this.currency = 'INR',
    required this.icon,
    this.accentColor = AppTheme.primaryPurple,
    this.trendPercent,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: AppDecorations.iconBadge(accentColor, radius: 14),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              if (trendPercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendPercent! >= 0 ? AppTheme.softGreenBadge : AppTheme.softRedBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendPercent! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: trendPercent! >= 0
                            ? AppTheme.inflowGreen
                            : AppTheme.outflowCoral,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatPercentage(trendPercent!),
                        style: AppTheme.tabularNumbers(
                          color: trendPercent! >= 0
                              ? AppTheme.inflowGreen
                              : AppTheme.outflowCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.formatCurrency(amount, currency: currency),
                style: AppTheme.tabularNumbers(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
