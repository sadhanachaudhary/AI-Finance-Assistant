import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../expenses/ui/add_expense_sheet.dart';
import '../../expenses/ui/smart_ingest_sheet.dart';
import '../../profile/ui/privacy_security_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).value;
    final expensesState = ref.watch(expensesProvider);
    final totalSpend = ref.watch(totalSpendProvider);
    final categorySpendMap = ref.watch(categorySpendMapProvider);

    // Find top spending category
    String topCategory = 'None';
    double topCategoryAmount = 0.0;
    categorySpendMap.forEach((key, val) {
      if (val > topCategoryAmount) {
        topCategory = key;
        topCategoryAmount = val;
      }
    });

    final userName = authUser?.name ?? authUser?.email.split('@').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: expensesState.when(
        loading: () => const AppLoading(message: 'Loading dashboard...'),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.read(expensesProvider.notifier).refresh(),
        ),
        data: (expenses) {
          final recentExpenses = expenses.take(4).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(expensesProvider.notifier).refresh();
              await ref.read(categoriesProvider.notifier).refresh();
            },
            color: const Color(0xFF6C63FF),
            backgroundColor: const Color(0xFF1E1E1E),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Balance Card
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    gradientColors: const [
                      Color(0xFF382A6E),
                      Color(0xFF1A1A2E),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spent (This Month)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.auto_graph_rounded,
                              color: Color(0xFF03DAC6),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Formatters.formatCurrency(totalSpend),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => PrivacySecuritySheet.show(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF03DAC6).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF03DAC6).withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_outlined, size: 13, color: Color(0xFF03DAC6)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Zero-Trust Privacy Shield Active',
                                      style: TextStyle(
                                        color: Color(0xFF03DAC6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right, size: 13, color: Color(0xFF03DAC6)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Metric Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Top Spending',
                          amount: topCategoryAmount,
                          subtitle: topCategory,
                          icon: Icons.pie_chart_outline_rounded,
                          accentColor: const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: StatCard(
                          title: 'Transactions',
                          amount: expenses.length.toDouble(),
                          currency: '',
                          subtitle: 'Total records',
                          icon: Icons.receipt_long_rounded,
                          accentColor: const Color(0xFF03DAC6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick Actions Row
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionButton(
                        icon: Icons.auto_awesome,
                        label: 'Auto-Track',
                        color: const Color(0xFF03DAC6),
                        onTap: () => SmartIngestSheet.show(context),
                      ),
                      _QuickActionButton(
                        icon: Icons.add_rounded,
                        label: 'Add Expense',
                        color: const Color(0xFF6C63FF),
                        onTap: () => AddExpenseSheet.show(context),
                      ),
                      _QuickActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Ask AI',
                        color: const Color(0xFFFFB74D),
                        onTap: () => context.go('/ai'),
                      ),
                      _QuickActionButton(
                        icon: Icons.insights_rounded,
                        label: 'Analytics',
                        color: const Color(0xFFE91E63),
                        onTap: () => context.go('/analytics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/expenses'),
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recentExpenses.isEmpty)
                    AppEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No expenses yet',
                      subtitle: 'Tap the button below to log your first transaction.',
                      actionText: 'Add First Expense',
                      onAction: () => AddExpenseSheet.show(context),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentExpenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final expense = recentExpenses[index];
                        return TransactionTile(
                          id: expense.id,
                          title: expense.merchant ?? 'Expense',
                          amount: expense.amount,
                          currency: expense.currency,
                          date: expense.date,
                          categoryName: expense.category?.name,
                          categoryIcon: expense.category?.parsedIcon,
                          categoryColor: expense.category?.parsedColor,
                          notes: expense.notes,
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
