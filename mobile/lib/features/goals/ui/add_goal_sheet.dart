import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/goal_provider.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalSheet(),
    );
  }

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialAmountController = TextEditingController();

  DateTime? _selectedDeadline = DateTime.now().add(const Duration(days: 90));
  String _selectedIcon = 'emergency';
  String _selectedColor = '0xFF10B981';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _iconPresets = [
    {'key': 'emergency', 'label': 'Safety', 'icon': Icons.shield_outlined, 'color': '0xFF10B981'},
    {'key': 'travel', 'label': 'Vacation', 'icon': Icons.flight_takeoff_rounded, 'color': '0xFF3B82F6'},
    {'key': 'laptop', 'label': 'Gadgets', 'icon': Icons.laptop_mac_rounded, 'color': '0xFF8B5CF6'},
    {'key': 'car', 'label': 'Vehicle', 'icon': Icons.directions_car_rounded, 'color': '0xFFF59E0B'},
    {'key': 'home', 'label': 'Home', 'icon': Icons.home_rounded, 'color': '0xFF06B6D4'},
    {'key': 'savings', 'label': 'General', 'icon': Icons.savings_outlined, 'color': '0xFFEC4899'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetAmountController.text.trim()) ?? 0;
    final initial = double.tryParse(_initialAmountController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    try {
      await ref.read(goalsProvider.notifier).addGoal(
        name: _nameController.text.trim(),
        targetAmount: target,
        currentAmount: initial,
        deadline: _selectedDeadline,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.inflowGreen,
            content: Text('🎉 Savings Goal "${_nameController.text.trim()}" activated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.outflowCoral, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.bgSlate,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.borderSlate, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.flag_circle_rounded, color: AppTheme.inflowGreen, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Create Savings Goal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preset Icon Selector
              const Text('Select Category / Icon', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconPresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _iconPresets[index];
                    final isSelected = _selectedIcon == item['key'];
                    final color = Color(int.parse(item['color']));

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = item['key'] as String;
                          _selectedColor = item['color'] as String;
                          if (_nameController.text.isEmpty) {
                            _nameController.text = '${item['label']} Fund';
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.25) : AppTheme.surfaceSlate,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : AppTheme.borderSlate,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData, color: isSelected ? Colors.white : color, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Goal Name
              AppTextField(
                controller: _nameController,
                labelText: 'Goal Title',
                hintText: 'e.g. Emergency Fund, New Laptop',
                prefixIcon: Icons.edit_note_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a goal title' : null,
              ),
              const SizedBox(height: 16),

              // Target Amount & Initial Deposit Row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _targetAmountController,
                      labelText: 'Target Amount (₹)',
                      hintText: '50000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppTextField(
                      controller: _initialAmountController,
                      labelText: 'Initial Deposit (₹)',
                      hintText: '0 (optional)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target Date
              const Text('Target Completion Date', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDeadline = picked);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSlate, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.trustTeal),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDeadline != null
                                ? '${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}'
                                : 'No deadline set',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Activate Goal',
                isLoading: _isLoading,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
