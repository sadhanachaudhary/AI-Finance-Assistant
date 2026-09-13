import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../expenses/providers/expense_provider.dart';
import '../providers/budget_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedIndex = -1;

  void _showEditBudgetDialog(String categoryName, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Budget for $categoryName',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.tabularNumbers(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Monthly Limit (₹)',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.trustTeal),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.trustBlue)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.trustBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newLimit = double.tryParse(controller.text.trim());
                if (newLimit != null && newLimit > 0) {
                  ref.read(categoryBudgetsProvider.notifier).setBudget(categoryName, newLimit);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Limit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(expensesProvider);
    final totalSpend = ref.watch(totalSpendProvider);
    final categorySpendMap = ref.watch(categorySpendMapProvider);
    final budgetsList = ref.watch(categoryBudgetsListProvider);
    final budgetSummary = ref.watch(overallBudgetSummaryProvider);

    final colors = AppTheme.chartTonalColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics & Budgets'),
      ),
      body: expensesState.when(
        loading: () => const AppLoading(message: 'Analyzing expenses...'),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.read(expensesProvider.notifier).refresh(),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No Data for Analytics',
              subtitle: 'Add some expenses first to view spending breakdowns and insights.',
            );
          }

          final entries = categorySpendMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Pie chart sections
          final pieSections = <PieChartSectionData>[];
          for (int i = 0; i < entries.length; i++) {
            final entry = entries[i];
            final percent = totalSpend > 0 ? (entry.value / totalSpend) * 100 : 0.0;
            final isTouched = i == _touchedIndex;
            final radius = isTouched ? 58.0 : 50.0;
            final color = colors[i % colors.length];

            pieSections.add(
              PieChartSectionData(
                color: color,
                value: entry.value,
                title: '${percent.toStringAsFixed(0)}%',
                radius: radius,
                titleStyle: AppTheme.tabularNumbers(
                  fontSize: isTouched ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final daysPassed = now.day;
          final dailyBurn = daysPassed > 0 ? totalSpend / daysPassed : 0.0;
          final forecastSpend = dailyBurn * daysInMonth;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Chart Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  gradientColors: const [Color(0xFF1E293B), Color(0xFF111827)],
                  child: Column(
                    children: [
                      const Text(
                        'Spending Breakdown by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 3,
                                centerSpaceRadius: 55,
                                sections: pieSections,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                                Text(
                                  Formatters.formatCurrency(totalSpend),
                                  style: AppTheme.tabularNumbers(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AI Forecast & Burn Rate Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  gradientColors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_graph_rounded, color: AppTheme.trustTeal, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI Spending Forecast (End of Month)',
                            style: TextStyle(color: AppTheme.trustTeal, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daily Burn Rate', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.formatCurrency(dailyBurn),
                                style: AppTheme.tabularNumbers(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Projected Month-End', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.formatCurrency(forecastSpend),
                                style: AppTheme.tabularNumbers(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly Budget vs Actual Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Budget Limits',
                      style: AppTypography.h2,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: AppDecorations.pillBadge(
                        budgetSummary.health == BudgetHealth.healthy
                            ? AppTheme.inflowGreen
                            : budgetSummary.health == BudgetHealth.warning
                                ? AppTheme.warningAmber
                                : AppTheme.outflowCoral,
                        radius: 10,
                      ),
                      child: Text(
                        '${(budgetSummary.percentage * 100).toStringAsFixed(0)}% Budget Used',
                        style: AppTheme.tabularNumbers(
                          color: budgetSummary.health == BudgetHealth.healthy
                              ? AppTheme.inflowGreen
                              : budgetSummary.health == BudgetHealth.warning
                                  ? AppTheme.warningAmber
                                  : AppTheme.outflowCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Budget Progress List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: budgetsList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = budgetsList[index];
                    final percent = item.percentage.clamp(0.0, 1.0);
                    final healthColor = item.health == BudgetHealth.healthy
                        ? AppTheme.inflowGreen
                        : item.health == BudgetHealth.warning
                            ? AppTheme.warningAmber
                            : AppTheme.outflowCoral;

                    return InkWell(
                      onTap: () => _showEditBudgetDialog(item.categoryName, item.budgetLimit),
                      borderRadius: BorderRadius.circular(16),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.categoryName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined, size: 14, color: Colors.white38),
                                  ],
                                ),
                                Text(
                                  '${Formatters.formatCurrency(item.spent)} / ${Formatters.formatCurrency(item.budgetLimit)}',
                                  style: AppTheme.tabularNumbers(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: healthColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.health == BudgetHealth.exceeded
                                      ? '⚠️ Over Budget'
                                      : item.health == BudgetHealth.warning
                                          ? 'Approaching limit'
                                          : 'On Track',
                                  style: TextStyle(fontSize: 10.5, color: healthColor, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${(item.percentage * 100).toStringAsFixed(1)}%',
                                  style: AppTheme.tabularNumbers(fontSize: 10.5, color: Colors.white38),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
