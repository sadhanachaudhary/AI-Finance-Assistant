import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../goals/providers/goal_provider.dart';
import '../../goals/models/goal_model.dart';
import '../../bills/ui/scan_bill_sheet.dart';
import '../../expenses/ui/add_expense_sheet.dart';
import '../../expenses/ui/smart_ingest_sheet.dart';
import '../../profile/ui/privacy_security_sheet.dart';
import '../../../shared/providers/security_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/ui/notifications_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).value;
    final expensesState = ref.watch(expensesProvider);
    final totalSpend = ref.watch(totalSpendProvider);
    final categorySpendMap = ref.watch(categorySpendMapProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final goalsState = ref.watch(goalsProvider);

    // Calculate dynamic income and balance or sensible defaults
    final estimatedIncome = totalSpend > 0 ? (totalSpend * 1.55).roundToDouble() : 54000.0;
    final totalBalance = (estimatedIncome - totalSpend).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'My Savings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Sparkle AI icon badge
          InkWell(
            onTap: () => context.go('/ai'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: AppDecorations.purpleGradientBadge(radius: 20),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          ),
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24, color: AppTheme.textPrimary),
                onPressed: () => NotificationsSheet.show(context),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.outflowCoral,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: expensesState.when(
        loading: () => const AppLoading(message: 'Loading your financial snapshot...'),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.read(expensesProvider.notifier).refresh(),
        ),
        data: (expenses) {
          final recentExpenses = expenses.take(4).toList();
          final goals = goalsState.value ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(expensesProvider.notifier).refresh();
              await ref.read(categoriesProvider.notifier).refresh();
              await ref.read(goalsProvider.notifier).refresh();
            },
            color: AppTheme.primaryPurple,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Balance Card (Matching Screen 1)
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    borderRadius: 24,
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL BALANCE',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatCurrency(totalBalance > 0 ? totalBalance : 2024.8),
                          style: AppTheme.tabularNumbers(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Income and Expense Dual Stats
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Income',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${Formatters.formatCurrency(estimatedIncome)}',
                                      style: AppTheme.tabularNumbers(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '-${Formatters.formatCurrency(totalSpend > 0 ? totalSpend : 3543.0)}',
                                      style: AppTheme.tabularNumbers(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // AI Optimization Banner Button
                        InkWell(
                          onTap: () => context.go('/ai'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleLight],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Grow savings with AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Ask now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionPill(
                          context: context,
                          label: 'Add Expense',
                          icon: Icons.add_circle_outline_rounded,
                          color: AppTheme.primaryPurple,
                          onTap: () => AddExpenseSheet.show(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionPill(
                          context: context,
                          label: 'Smart SMS',
                          icon: Icons.auto_awesome_outlined,
                          color: AppTheme.trustTeal,
                          onTap: () => SmartIngestSheet.show(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionPill(
                          context: context,
                          label: 'Scan Bill',
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.inflowGreen,
                          onTap: () => ScanBillSheet.show(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Goals Section ("My goals" with "See All")
                  SectionHeader(
                    title: 'My goals',
                    actionLabel: 'See All',
                    onActionTap: () => context.go('/goals'),
                    padding: const EdgeInsets.only(bottom: 12),
                  ),

                  if (goals.isNotEmpty)
                    ...goals.take(3).map((goal) => _buildGoalCard(goal, context))
                  else
                    _buildSampleGoals(context),

                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  SectionHeader(
                    title: 'Recent Transactions',
                    actionLabel: 'View All',
                    onActionTap: () => context.go('/expenses'),
                    padding: const EdgeInsets.only(bottom: 12),
                  ),

                  if (recentExpenses.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.textTertiary),
                          const SizedBox(height: 8),
                          const Text(
                            'No transactions recorded yet',
                            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () => AddExpenseSheet.show(context),
                            child: const Text('Add First Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentExpenses.map((exp) {
                      return TransactionTile(
                        id: exp.id,
                        title: exp.merchant ?? exp.category?.name ?? 'Expense',
                        amount: exp.amount,
                        currency: exp.currency,
                        date: exp.date,
                        categoryName: exp.category?.name,
                        categoryColor: exp.category?.parsedColor,
                        categoryIcon: exp.category?.parsedIcon,
                        notes: exp.notes,
                        isExpense: true,
                        onDelete: () => ref.read(expensesProvider.notifier).deleteExpense(exp.id),
                      );
                    }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal, BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => context.go('/goals'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(goal.targetAmount, currency: goal.currency),
                  style: AppTheme.tabularNumbers(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal.deadline != null ? Formatters.formatDate(goal.deadline!) : 'Target Goal',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: goal.percentage,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(goal.parsedColor),
                  strokeWidth: 4,
                ),
              ),
              Icon(
                goal.parsedIcon,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleGoals(BuildContext context) {
    final samples = [
      {'name': 'New Bike', 'amount': 4550.0, 'date': '1 Jan, 2025', 'icon': Icons.two_wheeler_rounded, 'pct': 0.65, 'color': AppTheme.warningAmber},
      {'name': 'Home', 'amount': 55000.0, 'date': '15 Feb, 2025', 'icon': Icons.home_rounded, 'pct': 0.82, 'color': AppTheme.inflowGreen},
      {'name': 'Business Savings', 'amount': 15000.0, 'date': '30 Mar, 2025', 'icon': Icons.business_center_rounded, 'pct': 0.40, 'color': AppTheme.primaryPurple},
    ];

    return Column(
      children: samples.map((s) {
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => context.go('/goals'),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(s['amount'] as double),
                      style: AppTheme.tabularNumbers(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['date'] as String,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: s['pct'] as double,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(s['color'] as Color),
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    s['icon'] as IconData,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
