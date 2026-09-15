import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class TransactionTile extends StatelessWidget {
  final String? id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String? categoryName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final String? notes;
  final bool isExpense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    this.id,
    required this.title,
    required this.amount,
    this.currency = 'INR',
    required this.date,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.notes,
    this.isExpense = true,
    this.onTap,
    this.onDelete,
  });

  void _showTransactionDetails(BuildContext context, Color effectiveColor, IconData effectiveIcon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
                const SizedBox(width: 14),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(effectiveIcon, color: effectiveColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : (categoryName ?? 'Expense'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        categoryName ?? 'General',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${Formatters.formatCurrency(amount, currency: currency)}',
                        style: AppTheme.tabularNumbers(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isExpense ? AppTheme.outflowCoral : AppTheme.inflowGreen,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.borderLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Date',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${Formatters.formatDate(date)} • ${Formatters.formatTime(date)}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  if (notes != null && notes!.isNotEmpty) ...[
                    const Divider(height: 24, color: AppTheme.borderLight),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notes / Ref',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            notes!,
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.softRedBadge,
                  foregroundColor: AppTheme.outflowCoral,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = categoryColor ?? AppTheme.primaryPurple;
    final effectiveIcon = categoryIcon ?? (isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined);

    return AppCard(
      onTap: onTap ?? () => _showTransactionDetails(context, effectiveColor, effectiveIcon),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              effectiveIcon,
              color: effectiveColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.isNotEmpty ? title : (categoryName ?? 'Expense'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        categoryName ?? 'General',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppTheme.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatShortDate(date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${Formatters.formatCurrency(amount, currency: currency)}',
                style: AppTheme.tabularNumbers(
                  color: isExpense ? AppTheme.textPrimary : AppTheme.inflowGreen,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.formatTime(date),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
