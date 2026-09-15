import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';

class BillLineItem {
  final String name;
  final int quantity;
  final double price;

  const BillLineItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class ScanBillSheet extends ConsumerStatefulWidget {
  const ScanBillSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScanBillSheet(),
    );
  }

  @override
  ConsumerState<ScanBillSheet> createState() => _ScanBillSheetState();
}

class _ScanBillSheetState extends ConsumerState<ScanBillSheet> {
  String _selectedMerchant = 'Starbucks Coffee';
  String _selectedCategoryName = 'Food & Dining';
  String? _selectedCategoryId;
  double _subtotal = 515.0;
  double _tax = 25.75;
  double _total = 540.75;
  bool _isScanning = false;
  bool _isSaved = false;

  List<BillLineItem> _items = [
    const BillLineItem(name: 'Caffe Latte (Grande)', quantity: 1, price: 295.0),
    const BillLineItem(name: 'Blueberry Muffin', quantity: 1, price: 220.0),
  ];

  final List<Map<String, dynamic>> _sampleReceipts = [
    {
      'label': '☕ Starbucks Receipt',
      'merchant': 'Starbucks Coffee',
      'category': 'Food & Dining',
      'subtotal': 515.0,
      'tax': 25.75,
      'total': 540.75,
      'items': [
        const BillLineItem(name: 'Caffe Latte (Grande)', quantity: 1, price: 295.0),
        const BillLineItem(name: 'Blueberry Muffin', quantity: 1, price: 220.0),
      ],
    },
    {
      'label': '🍕 Swiggy Invoice',
      'merchant': 'Gourmet Italian Bistro',
      'category': 'Food & Dining',
      'subtotal': 820.0,
      'tax': 41.0,
      'total': 861.0,
      'items': [
        const BillLineItem(name: 'Artisan Woodfire Pizza', quantity: 1, price: 480.0),
        const BillLineItem(name: 'Garlic Breadsticks', quantity: 1, price: 160.0),
      ],
    },
    {
      'label': '🛒 Supermarket Mart',
      'merchant': 'Fresh Groceries Market',
      'category': 'Groceries',
      'subtotal': 880.0,
      'tax': 0.0,
      'total': 880.0,
      'items': [
        const BillLineItem(name: 'Organic Almond Milk 1L', quantity: 2, price: 320.0),
        const BillLineItem(name: 'Whole Wheat Bread', quantity: 1, price: 140.0),
      ],
    },
  ];

  Future<void> _saveAsExpense() async {
    setState(() => _isScanning = true);
    try {
      final categories = ref.read(categoriesProvider).value ?? [];
      String? catId = _selectedCategoryId;
      if (catId == null) {
        for (final c in categories) {
          if (c.name.toLowerCase() == _selectedCategoryName.toLowerCase()) {
            catId = c.id;
            break;
          }
        }
      }

      await ref.read(expensesProvider.notifier).addExpense(
            amount: _total,
            date: DateTime.now(),
            merchant: _selectedMerchant,
            notes: 'Scanned Receipt: ${_items.map((i) => "${i.quantity}x ${i.name}").join(', ')}',
            categoryId: catId,
          );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryPurple,
            content: Text('🎉 Saved ${_selectedMerchant} receipt (${Formatters.formatCurrency(_total)})!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.outflowCoral),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.softPurpleBadge,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryPurple, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Receipt & Bill Scanner',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Instant optical line-item extraction',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Demo samples
            const Text('Sample Bills:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleReceipts.map((sample) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(sample['label']),
                      backgroundColor: AppTheme.surfaceElevated,
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setState(() {
                          _selectedMerchant = sample['merchant'];
                          _selectedCategoryName = sample['category'];
                          _subtotal = sample['subtotal'];
                          _tax = sample['tax'];
                          _total = sample['total'];
                          _items = List<BillLineItem>.from(sample['items']);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Scanned Receipt Preview Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMerchant,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.softPurpleBadge,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedCategoryName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppTheme.borderLight),
                  ..._items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                          Text(Formatters.formatCurrency(item.price), style: AppTheme.tabularNumbers(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20, color: AppTheme.borderLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                      Text(
                        Formatters.formatCurrency(_total),
                        style: AppTheme.tabularNumbers(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primaryPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            AppButton(
              text: 'Save Scanned Bill as Expense',
              onPressed: _saveAsExpense,
              isLoading: _isScanning,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
