import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
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

    Navigator.pop(context);
  }

  void _applyFilters() {
    ref.read(dateFilterPresetProvider.notifier).state = _selectedDatePreset;
    ref.read(customDateRangeProvider.notifier).state = _selectedDateRange;
    ref.read(sortOptionProvider.notifier).state = _selectedSortOption;

    final minVal = double.tryParse(_minAmountController.text.trim());
    final maxVal = double.tryParse(_maxAmountController.text.trim());
    ref.read(minAmountFilterProvider.notifier).state = minVal;
    ref.read(maxAmountFilterProvider.notifier).state = maxVal;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset All', style: TextStyle(color: AppTheme.outflowCoral, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SortOption.values.map((opt) {
                final isSelected = _selectedSortOption == opt;
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  side: BorderSide(color: isSelected ? AppTheme.primaryPurple : AppTheme.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSortOption = opt);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DateFilterPreset.values.map((preset) {
                final isSelected = _selectedDatePreset == preset;
                return ChoiceChip(
                  label: Text(preset.label),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  side: BorderSide(color: isSelected ? AppTheme.primaryPurple : AppTheme.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDatePreset = preset);
                      if (preset == DateFilterPreset.custom) _pickDateRange();
                    }
                  },
                );
              }).toList(),
            ),
            if (_selectedDatePreset == DateFilterPreset.custom && _selectedDateRange != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.softPurpleBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: _pickDateRange,
                      child: const Text('Change', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Amount Range (₹)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _minAmountController,
                    hintText: 'Min (e.g. 100)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _maxAmountController,
                    hintText: 'Max (e.g. 5000)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            AppButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
