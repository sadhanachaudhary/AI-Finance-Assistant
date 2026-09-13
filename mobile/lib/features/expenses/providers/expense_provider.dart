import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepository(apiClient);
});

// Category State
final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() => CategoriesNotifier());

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  late ExpenseRepository _repo;

  @override
  Future<List<Category>> build() async {
    _repo = ref.watch(expenseRepositoryProvider);
    return _repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getCategories());
  }

  Future<void> addCategory(String name, String? icon, String? color) async {
    try {
      final newCat = await _repo.createCategory(name: name, icon: icon, color: color);
      state = AsyncValue.data([...state.value ?? [], newCat]);
    } catch (_) {
      rethrow;
    }
  }
}

// Expense State
final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() => ExpensesNotifier());

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  late ExpenseRepository _repo;

  @override
  Future<List<Expense>> build() async {
    _repo = ref.watch(expenseRepositoryProvider);
    return _repo.getExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getExpenses());
  }

  Future<void> addExpense({
    required double amount,
    String currency = 'INR',
    required DateTime date,
    String? merchant,
    String? notes,
    String? categoryId,
  }) async {
    final created = await _repo.createExpense(
      amount: amount,
      currency: currency,
      date: date,
      merchant: merchant,
      notes: notes,
      categoryId: categoryId,
    );
    // Find category object if available
    final categories = ref.read(categoriesProvider).value ?? [];
    final matchedCat = categories.cast<Category?>().firstWhere(
          (c) => c?.id == categoryId,
          orElse: () => null,
        );

    final finalExpense = Expense(
      id: created.id,
      userId: created.userId,
      amount: created.amount,
      currency: created.currency,
      date: created.date,
      merchant: created.merchant,
      notes: created.notes,
      categoryId: created.categoryId,
      category: created.category ?? matchedCat,
    );

    state = AsyncValue.data([finalExpense, ...(state.value ?? [])]);
  }

  Future<void> deleteExpense(String id) async {
    final previousState = state.value ?? [];
    state = AsyncValue.data(previousState.where((e) => e.id != id).toList());
    try {
      await _repo.deleteExpense(id);
    } catch (e) {
      // Revert if failed
      state = AsyncValue.data(previousState);
      rethrow;
    }
  }
}

// Filter & Sort Enums
enum DateFilterPreset {
  all('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  custom('Custom');

  final String label;
  const DateFilterPreset(this.label);
}

enum SortOption {
  dateDesc('Newest First'),
  dateAsc('Oldest First'),
  amountDesc('Highest Amount'),
  amountAsc('Lowest Amount'),
  merchantAsc('Merchant (A-Z)');

  final String label;
  const SortOption(this.label);
}

// Filter States using Notifiers
class SelectedCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? val) => super.state = val;
}
final selectedCategoryFilterProvider = NotifierProvider<SelectedCategoryFilterNotifier, String?>(SelectedCategoryFilterNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String val) => super.state = val;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class DateFilterPresetNotifier extends Notifier<DateFilterPreset> {
  @override
  DateFilterPreset build() => DateFilterPreset.all;
  @override
  set state(DateFilterPreset val) => super.state = val;
}
final dateFilterPresetProvider = NotifierProvider<DateFilterPresetNotifier, DateFilterPreset>(DateFilterPresetNotifier.new);

class CustomDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  @override
  set state(DateTimeRange? val) => super.state = val;
}
final customDateRangeProvider = NotifierProvider<CustomDateRangeNotifier, DateTimeRange?>(CustomDateRangeNotifier.new);

class SortOptionNotifier extends Notifier<SortOption> {
  @override
  SortOption build() => SortOption.dateDesc;
  @override
  set state(SortOption val) => super.state = val;
}
final sortOptionProvider = NotifierProvider<SortOptionNotifier, SortOption>(SortOptionNotifier.new);

class MinAmountFilterNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  @override
  set state(double? val) => super.state = val;
}
final minAmountFilterProvider = NotifierProvider<MinAmountFilterNotifier, double?>(MinAmountFilterNotifier.new);

class MaxAmountFilterNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  @override
  set state(double? val) => super.state = val;
}
final maxAmountFilterProvider = NotifierProvider<MaxAmountFilterNotifier, double?>(MaxAmountFilterNotifier.new);

// Active Filters Count (for badge indication)
final activeFiltersCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(selectedCategoryFilterProvider) != null) count++;
  if (ref.watch(dateFilterPresetProvider) != DateFilterPreset.all) count++;
  if (ref.watch(sortOptionProvider) != SortOption.dateDesc) count++;
  if (ref.watch(minAmountFilterProvider) != null) count++;
  if (ref.watch(maxAmountFilterProvider) != null) count++;
  return count;
});

// Filtered & Sorted Expenses
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final selectedCat = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final datePreset = ref.watch(dateFilterPresetProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final sortOption = ref.watch(sortOptionProvider);
  final minAmount = ref.watch(minAmountFilterProvider);
  final maxAmount = ref.watch(maxAmountFilterProvider);

  final now = DateTime.now();

  final filtered = expenses.where((e) {
    // Category match
    if (selectedCat != null && e.categoryId != selectedCat) {
      return false;
    }

    // Search query match
    if (query.isNotEmpty) {
      final matchesSearch = (e.merchant?.toLowerCase().contains(query) ?? false) ||
          (e.notes?.toLowerCase().contains(query) ?? false) ||
          (e.category?.name.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;
    }

    // Amount range match
    if (minAmount != null && e.amount < minAmount) return false;
    if (maxAmount != null && e.amount > maxAmount) return false;

    // Date range match
    switch (datePreset) {
      case DateFilterPreset.all:
        break;
      case DateFilterPreset.today:
        if (e.date.year != now.year || e.date.month != now.month || e.date.day != now.day) {
          return false;
        }
        break;
      case DateFilterPreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        if (e.date.isBefore(startOfDay)) return false;
        break;
      case DateFilterPreset.thisMonth:
        if (e.date.year != now.year || e.date.month != now.month) {
          return false;
        }
        break;
      case DateFilterPreset.lastMonth:
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        if (e.date.year != lastMonthYear || e.date.month != lastMonth) {
          return false;
        }
        break;
      case DateFilterPreset.custom:
        if (customRange != null) {
          final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          if (e.date.isBefore(start) || e.date.isAfter(end)) {
            return false;
          }
        }
        break;
    }

    return true;
  }).toList();

  // Sorting
  switch (sortOption) {
    case SortOption.dateDesc:
      filtered.sort((a, b) => b.date.compareTo(a.date));
      break;
    case SortOption.dateAsc:
      filtered.sort((a, b) => a.date.compareTo(b.date));
      break;
    case SortOption.amountDesc:
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
      break;
    case SortOption.amountAsc:
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
      break;
    case SortOption.merchantAsc:
      filtered.sort((a, b) => (a.merchant ?? '').compareTo(b.merchant ?? ''));
      break;
  }

  return filtered;
});

// Summary Metrics Providers
final totalSpendProvider = Provider<double>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
});

final categorySpendMapProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final map = <String, double>{};

  for (final exp in expenses) {
    final name = exp.category?.name ?? 'Other';
    map[name] = (map[name] ?? 0.0) + exp.amount;
  }
  return map;
});
