import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/providers/expense_provider.dart';

enum BudgetHealth {
  healthy, // < 70%
  warning, // 70% - 90%
  exceeded, // > 90%
}

class CategoryBudget {
  final String categoryName;
  final double budgetLimit;
  final double spent;

  const CategoryBudget({
    required this.categoryName,
    required this.budgetLimit,
    required this.spent,
  });

  double get percentage => budgetLimit > 0 ? (spent / budgetLimit) : 0.0;

  BudgetHealth get health {
    if (percentage >= 0.90) return BudgetHealth.exceeded;
    if (percentage >= 0.70) return BudgetHealth.warning;
    return BudgetHealth.healthy;
  }
}

class CategoryBudgetsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    return {
      'Food & Dining': 5000.0,
      'Shopping': 6000.0,
      'Transportation': 3500.0,
      'Entertainment': 2500.0,
      'Bills & Utilities': 4500.0,
      'Health & Fitness': 2500.0,
      'Groceries': 6000.0,
      'Travel': 10000.0,
    };
  }

  void setBudget(String categoryName, double limit) {
    state = {
      ...state,
      categoryName: limit,
    };
  }
}

final categoryBudgetsProvider = NotifierProvider<CategoryBudgetsNotifier, Map<String, double>>(
  CategoryBudgetsNotifier.new,
);

final categoryBudgetsListProvider = Provider<List<CategoryBudget>>((ref) {
  final budgetsMap = ref.watch(categoryBudgetsProvider);
  final categorySpendMap = ref.watch(categorySpendMapProvider);

  final list = <CategoryBudget>[];

  budgetsMap.forEach((catName, limit) {
    final spent = categorySpendMap[catName] ?? 0.0;
    list.add(
      CategoryBudget(
        categoryName: catName,
        budgetLimit: limit,
        spent: spent,
      ),
    );
  });

  // Sort by percentage descending
  list.sort((a, b) => b.percentage.compareTo(a.percentage));
  return list;
});

class OverallBudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double percentage;
  final BudgetHealth health;

  const OverallBudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.percentage,
    required this.health,
  });
}

final overallBudgetSummaryProvider = Provider<OverallBudgetSummary>((ref) {
  final budgetsList = ref.watch(categoryBudgetsListProvider);
  final totalBudget = budgetsList.fold<double>(0.0, (sum, b) => sum + b.budgetLimit);
  final totalSpent = budgetsList.fold<double>(0.0, (sum, b) => sum + b.spent);

  final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

  BudgetHealth health = BudgetHealth.healthy;
  if (percentage >= 0.90) {
    health = BudgetHealth.exceeded;
  } else if (percentage >= 0.70) {
    health = BudgetHealth.warning;
  }

  return OverallBudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    percentage: percentage,
    health: health,
  );
});
