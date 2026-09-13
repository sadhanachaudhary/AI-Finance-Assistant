import 'package:flutter/material.dart';
import '../utils/formatters.dart';

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

  @override
  Widget build(BuildContext context) {
    final effectiveColor = categoryColor ?? (isExpense ? const Color(0xFF6C63FF) : const Color(0xFF03DAC6));
    final effectiveIcon = categoryIcon ?? (isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined);

    Widget tileContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Row(
        children: [
          // Category Icon Container
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              effectiveIcon,
              color: effectiveColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Title & Category/Date Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : (categoryName ?? 'Expense'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (categoryName != null) ...[
                      Text(
                        categoryName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: effectiveColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                    Text(
                      Formatters.formatDate(date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                if (notes != null && notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white30,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount
          Text(
            '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(amount, currency: currency)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.white : const Color(0xFF03DAC6),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );

    Widget interactiveContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: effectiveColor.withValues(alpha: 0.1),
        highlightColor: effectiveColor.withValues(alpha: 0.05),
        child: tileContent,
      ),
    );

    if (onDelete != null) {
      final dismissKey = id != null 
          ? ValueKey(id!) 
          : ValueKey('${title}_${date.millisecondsSinceEpoch}_$amount');

      return Dismissible(
        key: dismissKey,
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFCF6679).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
            ],
          ),
        ),
        onDismissed: (_) => onDelete!(),
        child: interactiveContent,
      );
    }

    return interactiveContent;
  }
}
