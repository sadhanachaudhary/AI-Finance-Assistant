import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF14141E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2C2C3E), width: 1.5)),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(effectiveIcon, color: effectiveColor, size: 26),
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
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryName ?? 'Uncategorized',
                        style: TextStyle(fontSize: 13, color: effectiveColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCurrency(amount, currency: currency),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date, Day & Time Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              gradientColors: const [Color(0xFF201D38), Color(0xFF141324)],
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Day & Date',
                    value: '${Formatters.formatDayOfWeek(date)}, ${date.day} ${_getMonthName(date.month)} ${date.year}',
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time of Expense',
                    value: Formatters.formatTime(date),
                  ),
                  if (notes != null && notes!.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 20),
                    _buildDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Details / Line Items',
                      value: notes!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF03DAC6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                Text.rich(
                  TextSpan(
                    children: [
                      if (categoryName != null) ...[
                        TextSpan(
                          text: categoryName!,
                          style: TextStyle(
                            color: effectiveColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text: ' • ',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                      TextSpan(
                        text: Formatters.formatDate(date),
                        style: const TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
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
        onTap: onTap ?? () => _showTransactionDetails(context, effectiveColor, effectiveIcon),
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
