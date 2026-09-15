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
  String _selectedColor = '0xFF6C5CE7';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _iconPresets = [
    {'key': 'emergency', 'label': 'Safety', 'icon': Icons.shield_outlined, 'color': '0xFF10B981'},
    {'key': 'travel', 'label': 'Vacation', 'icon': Icons.flight_takeoff_rounded, 'color': '0xFF6C5CE7'},
    {'key': 'laptop', 'label': 'Gadgets', 'icon': Icons.laptop_mac_rounded, 'color': '0xFF8E7CFF'},
    {'key': 'car', 'label': 'Vehicle', 'icon': Icons.directions_car_rounded, 'color': '0xFFF59E0B'},
    {'key': 'home', 'label': 'Home', 'icon': Icons.home_rounded, 'color': '0xFF10B981'},
    {'key': 'savings', 'label': 'General', 'icon': Icons.savings_outlined, 'color': '0xFF6C5CE7'},
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
            backgroundColor: AppTheme.primaryPurple,
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
                    'Create Savings Target',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                labelText: 'Goal Title',
                hintText: 'e.g., Emergency Cushion, iPhone 16, Bali Vacation',
                prefixIcon: Icons.flag_rounded,
                autofocus: true,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter goal title' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _targetAmountController,
                      labelText: 'Target (₹)',
                      hintText: '50000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee,
                      validator: (val) {
                        final n = double.tryParse(val ?? '');
                        if (n == null || n <= 0) return 'Invalid target';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _initialAmountController,
                      labelText: 'Initial Deposit (₹)',
                      hintText: '0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.savings_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Goal Category / Icon', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _iconPresets.map((preset) {
                    final isSelected = _selectedIcon == preset['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIcon = preset['key'] as String;
                            _selectedColor = preset['color'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.softPurpleBadge : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryPurple : AppTheme.borderLight,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                preset['icon'] as IconData,
                                color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                preset['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Activate Goal',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.rocket_launch_rounded,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
