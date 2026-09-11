import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../providers/expense_provider.dart';
import 'add_expense_sheet.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(expensesProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final totalSpend = ref.watch(totalSpendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(expensesProvider.notifier).refresh();
              ref.read(categoriesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddExpenseSheet.show(context),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: expensesState.when(
        loading: () => const AppLoading(message: 'Loading your expenses...'),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.read(expensesProvider.notifier).refresh(),
        ),
        data: (expenses) {
          final categories = categoriesState.value ?? [];

          return RefreshIndicator(
            onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
            color: const Color(0xFF6C63FF),
            backgroundColor: const Color(0xFF1E1E1E),
            child: CustomScrollView(
              slivers: [
                // Top Search & Summary Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        AppTextField(
                          controller: _searchController,
                          hintText: 'Search merchant, notes, category...',
                          prefixIcon: Icons.search_rounded,
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              CategoryChip(
                                label: 'All',
                                isSelected: selectedCat == null,
                                onSelected: (_) {
                                  ref.read(selectedCategoryFilterProvider.notifier).state = null;
                                },
                              ),
                              const SizedBox(width: 8),
                              ...categories.map((cat) {
                                final isSelected = selectedCat == cat.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CategoryChip(
                                    label: cat.name,
                                    icon: cat.parsedIcon,
                                    color: cat.parsedColor,
                                    isSelected: isSelected,
                                    onSelected: (selected) {
                                      ref.read(selectedCategoryFilterProvider.notifier).state =
                                          selected ? cat.id : null;
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Summary info bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredExpenses.length} ${filteredExpenses.length == 1 ? 'Transaction' : 'Transactions'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Total: ${Formatters.formatCurrency(totalSpend)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF03DAC6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Transactions List
                if (filteredExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses found',
                      subtitle: selectedCat != null || _searchController.text.isNotEmpty
                          ? 'Try clearing your search or category filter'
                          : 'Start tracking your spending by adding your first expense!',
                      actionText: selectedCat != null || _searchController.text.isNotEmpty
                          ? 'Clear Filters'
                          : 'Add Expense',
                      onAction: () {
                        if (selectedCat != null || _searchController.text.isNotEmpty) {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(selectedCategoryFilterProvider.notifier).state = null;
                        } else {
                          AddExpenseSheet.show(context);
                        }
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = filteredExpenses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionTile(
                              title: expense.merchant ?? 'Expense',
                              amount: expense.amount,
                              currency: expense.currency,
                              date: expense.date,
                              categoryName: expense.category?.name,
                              categoryIcon: expense.category?.parsedIcon,
                              categoryColor: expense.category?.parsedColor,
                              notes: expense.notes,
                              onDelete: () async {
                                try {
                                  await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Expense deleted')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: $e'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                        childCount: filteredExpenses.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}
