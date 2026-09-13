import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../providers/expense_provider.dart';
import 'add_expense_sheet.dart';
import 'filter_bottom_sheet.dart';
import 'smart_ingest_sheet.dart';

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

  void _clearAllFilters() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryFilterProvider.notifier).state = null;
    ref.read(dateFilterPresetProvider.notifier).state = DateFilterPreset.all;
    ref.read(customDateRangeProvider.notifier).state = null;
    ref.read(sortOptionProvider.notifier).state = SortOption.dateDesc;
    ref.read(minAmountFilterProvider.notifier).state = null;
    ref.read(maxAmountFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(expensesProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final selectedDatePreset = ref.watch(dateFilterPresetProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);

    // Calculate sum of currently filtered subset
    final filteredTotal = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.trustTeal),
            tooltip: 'Smart Auto-Track',
            onPressed: () => SmartIngestSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Expense',
            onPressed: () => AddExpenseSheet.show(context),
          ),
          // Filter & Sort Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter & Sort',
                onPressed: () => FilterBottomSheet.show(context),
              ),
              if (activeFiltersCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.trustBlue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$activeFiltersCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(expensesProvider.notifier).refresh();
              ref.read(categoriesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddExpenseSheet.show(context),
        backgroundColor: AppTheme.trustBlue,
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
            color: AppTheme.trustBlue,
            backgroundColor: AppTheme.surfaceSlate,
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
                        const SizedBox(height: 12),
                        // Quick Date Range Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: DateFilterPreset.values.map((preset) {
                              final isSelected = selectedDatePreset == preset;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(preset.label),
                                  selected: isSelected,
                                  selectedColor: AppTheme.trustBlue,
                                  backgroundColor: AppTheme.surfaceSlate,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.trustBlue : AppTheme.borderSlate,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onSelected: (selected) {
                                    if (selected) {
                                      if (preset == DateFilterPreset.custom) {
                                        FilterBottomSheet.show(context);
                                      } else {
                                        ref.read(dateFilterPresetProvider.notifier).state = preset;
                                      }
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 14),
                        // Summary info bar & Active Filters Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${filteredExpenses.length} ${filteredExpenses.length == 1 ? 'Transaction' : 'Transactions'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (activeFiltersCount > 0 || _searchController.text.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _clearAllFilters,
                                    child: const Text(
                                      'Clear all',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.outflowCoral,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'Total: ${Formatters.formatCurrency(filteredTotal)}',
                              style: AppTheme.tabularNumbers(
                                fontSize: 14,
                                color: AppTheme.inflowGreen,
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
                      subtitle: activeFiltersCount > 0 || _searchController.text.isNotEmpty
                          ? 'Try adjusting or clearing your active filters'
                          : 'Start tracking your spending by adding your first expense!',
                      actionText: activeFiltersCount > 0 || _searchController.text.isNotEmpty
                          ? 'Clear Filters'
                          : 'Add Expense',
                      onAction: () {
                        if (activeFiltersCount > 0 || _searchController.text.isNotEmpty) {
                          _clearAllFilters();
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
                              id: expense.id,
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
                                        backgroundColor: AppTheme.outflowCoral,
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
