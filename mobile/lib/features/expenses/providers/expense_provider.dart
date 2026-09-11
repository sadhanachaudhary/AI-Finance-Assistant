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

// Filter States
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Expenses
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final selectedCat = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return expenses.where((e) {
    final matchesCategory = selectedCat == null || e.categoryId == selectedCat;
    final matchesSearch = query.isEmpty ||
        (e.merchant?.toLowerCase().contains(query) ?? false) ||
        (e.notes?.toLowerCase().contains(query) ?? false) ||
        (e.category?.name.toLowerCase().contains(query) ?? false);
    return matchesCategory && matchesSearch;
  }).toList();
});

// Summary Metrics Providers
final totalSpendProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
});

final categorySpendMapProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final map = <String, double>{};

  for (final exp in expenses) {
    final name = exp.category?.name ?? 'Other';
    map[name] = (map[name] ?? 0.0) + exp.amount;
  }
  return map;
});
