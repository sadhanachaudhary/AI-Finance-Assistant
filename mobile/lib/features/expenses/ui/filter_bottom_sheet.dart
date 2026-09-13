import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/expense_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late DateFilterPreset _selectedDatePreset;
  DateTimeRange? _selectedDateRange;
  late SortOption _selectedSortOption;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDatePreset = ref.read(dateFilterPresetProvider);
    _selectedDateRange = ref.read(customDateRangeProvider);
    _selectedSortOption = ref.read(sortOptionProvider);

    final minAmt = ref.read(minAmountFilterProvider);
    final maxAmt = ref.read(maxAmountFilterProvider);
    if (minAmt != null) _minAmountController.text = minAmt.toStringAsFixed(0);
    if (maxAmt != null) _maxAmountController.text = maxAmt.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDatePreset = DateFilterPreset.custom;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDatePreset = DateFilterPreset.all;
      _selectedDateRange = null;
      _selectedSortOption = SortOption.dateDesc;
      _minAmountController.clear();
      _maxAmountController.clear();
    });

    ref.read(dateFilterPresetProvider.notifier).state = DateFilterPreset.all;
    ref.read(customDateRangeProvider.notifier).state = null;
    ref.read(sortOptionProvider.notifier).state = SortOption.dateDesc;
    ref.read(minAmountFilterProvider.notifier).state = null;
    ref.read(maxAmountFilterProvider.notifier).state = null;
    ref.read(selectedCategoryFilterProvider.notifier).state = null;
    ref.read(searchQueryProvider.notifier).state = '';

    Navigator.of(context).pop();
  }

  void _applyFilters() {
    final minVal = double.tryParse(_minAmountController.text.trim());
    final maxVal = double.tryParse(_maxAmountController.text.trim());

    ref.read(dateFilterPresetProvider.notifier).state = _selectedDatePreset;
    ref.read(customDateRangeProvider.notifier).state = _selectedDateRange;
    ref.read(sortOptionProvider.notifier).state = _selectedSortOption;
    ref.read(minAmountFilterProvider.notifier).state = minVal;
    ref.read(maxAmountFilterProvider.notifier).state = maxVal;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2C2C2C), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title & Reset
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
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset All',
                  style: TextStyle(
                    color: Color(0xFFCF6679),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Date Range
                  const Text(
                    'DATE TIMELINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DateFilterPreset.values.map((preset) {
                      final isSelected = _selectedDatePreset == preset;
                      return ChoiceChip(
                        label: Text(preset.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6C63FF),
                        backgroundColor: const Color(0xFF252525),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF333333),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (selected) {
                          if (selected) {
                            if (preset == DateFilterPreset.custom) {
                              _pickDateRange();
                            } else {
                              setState(() {
                                _selectedDatePreset = preset;
                              });
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedDatePreset == DateFilterPreset.custom && _selectedDateRange != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            Text(
                              '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_outlined, size: 16, color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Section 2: Sort By
                  const Text(
                    'SORT ORDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOption.values.map((sort) {
                      final isSelected = _selectedSortOption == sort;
                      return ChoiceChip(
                        label: Text(sort.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6C63FF),
                        backgroundColor: const Color(0xFF252525),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF333333),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSortOption = sort;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Section 3: Amount Range
                  const Text(
                    'AMOUNT RANGE (₹)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _minAmountController,
                          hintText: 'Min Amount',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('-', style: TextStyle(color: Colors.white38, fontSize: 18)),
                      ),
                      Expanded(
                        child: AppTextField(
                          controller: _maxAmountController,
                          hintText: 'Max Amount',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Apply Button
          AppButton(
            text: 'Apply Filters',
            onPressed: _applyFilters,
          ),
        ],
      ),
    );
  }
}
