import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../expenses/providers/expense_provider.dart';

class ExportStatementSheet extends ConsumerStatefulWidget {
  const ExportStatementSheet({super.key});

  static Future<void> show(BuildContext context) {
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
        backgroundColor: Color(0xFF03DAC6),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2C2C3E), width: 1.5)),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to Profile',
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_download_outlined, color: Color(0xFF6C63FF), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Spending Statement',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Download CSV/Excel format',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              gradientColors: const [Color(0xFF22203C), Color(0xFF161528)],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Records', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text('${expenses.length} transactions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                        Formatters.formatCurrency(totalSpend),
                        style: const TextStyle(color: Color(0xFF03DAC6), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Format', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('CSV / Spreadsheet', style: TextStyle(color: Color(0xFF8B80F9), fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preview Box
            const Text(
              'Statement Preview',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: Text(
                expenses.take(4).map((e) => '${Formatters.formatDate(e.date)} • ${e.merchant} • ₹${e.amount}').join('\n') +
                    (expenses.length > 4 ? '\n... and ${expenses.length - 4} more transactions' : ''),
                style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontFamily: 'monospace', height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // Copy & Export Action
            AppButton(
              text: _isCopied ? 'Copied to Clipboard!' : 'Copy CSV to Clipboard',
              icon: _isCopied ? Icons.check_rounded : Icons.copy_rounded,
              onPressed: () => _copyCsv(expenses),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
