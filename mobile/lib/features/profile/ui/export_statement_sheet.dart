import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../expenses/providers/expense_provider.dart';

class ExportStatementSheet extends ConsumerStatefulWidget {
  const ExportStatementSheet({super.key});

  static Future<void> show(BuildContext context, [List<dynamic>? _]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportStatementSheet(),
    );
  }

  @override
  ConsumerState<ExportStatementSheet> createState() => _ExportStatementSheetState();
}

class _ExportStatementSheetState extends ConsumerState<ExportStatementSheet> {
  bool _isCopied = false;

  String _generateCsv(List<dynamic> expenses) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Merchant,Category,Amount,Currency,Notes');

    for (final exp in expenses) {
      final id = exp.id;
      final date = Formatters.formatDate(exp.date);
      final merchant = (exp.merchant ?? 'Expense').replaceAll(',', ' ');
      final category = (exp.category?.name ?? 'Uncategorized').replaceAll(',', ' ');
      final amount = exp.amount.toStringAsFixed(2);
      final currency = exp.currency ?? 'INR';
      final notes = (exp.notes ?? '').replaceAll(',', ' ');

      buffer.writeln('$id,$date,$merchant,$category,$amount,$currency,$notes');
    }

    return buffer.toString();
  }

  void _copyCsv(List<dynamic> expenses) {
    final csv = _generateCsv(expenses);
    Clipboard.setData(ClipboardData(text: csv));
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('CSV Statement copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider).value ?? [];
    final totalSpend = ref.watch(totalSpendProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.softPurpleBadge,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Statement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Download full transaction history',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Records', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${expenses.length} Entries', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Gross Total', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(totalSpend),
                        style: AppTheme.tabularNumbers(color: AppTheme.primaryPurple, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Formats List
            const Text('Available Formats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),

            AppCard(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => _copyCsv(expenses),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.softPurpleBadge,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppTheme.primaryPurple, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CSV Format (Spreadsheet)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Compatible with Excel, Google Sheets, Apple Numbers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Icon(
                    _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                    color: _isCopied ? AppTheme.inflowGreen : AppTheme.primaryPurple,
                    size: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            AppButton(
              text: _isCopied ? 'Copied to Clipboard!' : 'Copy Statement Data',
              onPressed: () => _copyCsv(expenses),
              icon: _isCopied ? Icons.check_rounded : Icons.copy_rounded,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
