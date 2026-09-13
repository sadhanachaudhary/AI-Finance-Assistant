import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/category_chip.dart';
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
      'label': '🍕 Swiggy Dinner Invoice',
      'merchant': 'Gourmet Italian Bistro',
      'category': 'Food & Dining',
      'subtotal': 820.0,
      'tax': 41.0,
      'total': 861.0,
      'items': [
        const BillLineItem(name: 'Artisan Woodfire Pizza', quantity: 1, price: 480.0),
        const BillLineItem(name: 'Garlic Breadsticks', quantity: 1, price: 160.0),
        const BillLineItem(name: 'Iced Lemon Tea (2x)', quantity: 2, price: 180.0),
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
        const BillLineItem(name: 'Avocados (Pack of 2)', quantity: 1, price: 180.0),
        const BillLineItem(name: 'Whole Wheat Sourdough', quantity: 1, price: 140.0),
        const BillLineItem(name: 'Greek Yogurt 400g', quantity: 2, price: 240.0),
      ],
    },
    {
      'label': '💊 Apollo Pharmacy',
      'merchant': 'Apollo Pharmacy',
      'category': 'Health & Fitness',
      'subtotal': 545.0,
      'tax': 27.25,
      'total': 572.25,
      'items': [
        const BillLineItem(name: 'Multivitamin Complex 60s', quantity: 1, price: 450.0),
        const BillLineItem(name: 'Antiseptic Ointment 50g', quantity: 1, price: 95.0),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _matchCategory(_selectedCategoryName));
  }

  void _matchCategory(String catName) {
    final categories = ref.read(categoriesProvider).value ?? [];
    try {
      final matched = categories.firstWhere(
        (c) => c.name.toLowerCase() == catName.toLowerCase(),
      );
      setState(() {
        _selectedCategoryId = matched.id;
      });
    } catch (_) {
      if (categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = categories.first.id;
        });
      }
    }
  }

  void _loadReceiptPreset(Map<String, dynamic> sample) {
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _selectedMerchant = sample['merchant'];
          _selectedCategoryName = sample['category'];
          _subtotal = sample['subtotal'];
          _tax = sample['tax'];
          _total = sample['total'];
          _items = List<BillLineItem>.from(sample['items']);
          _isScanning = false;
        });
        _matchCategory(_selectedCategoryName);
      }
    });
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isSaved = true);

    try {
      final itemSummary = _items.map((i) => '${i.quantity}x ${i.name}').join(', ');
      await ref.read(expensesProvider.notifier).addExpense(
            amount: _total,
            date: DateTime.now(),
            merchant: _selectedMerchant,
            notes: 'AI OCR: $itemSummary (Tax: ₹${_tax.toStringAsFixed(2)})',
            categoryId: _selectedCategoryId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Logged ₹${_total.toStringAsFixed(2)} receipt for $_selectedMerchant!'),
              ],
            ),
            backgroundColor: const Color(0xFF03DAC6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaved = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2C2C3E), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
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
            const SizedBox(height: 18),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03DAC6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF03DAC6), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Receipt & Bill Scanner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Auto-extract line items, taxes & total',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera / File Upload Simulation Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C3E), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Capture Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _loadReceiptPreset(_sampleReceipts[0]),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Upload PDF/Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF3E3E50)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _loadReceiptPreset(_sampleReceipts[1]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Or choose a sample receipt to test OCR parsing:',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sampleReceipts.map((sample) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF14141E),
                            side: const BorderSide(color: Color(0xFF3E3E50)),
                            label: Text(
                              sample['label'],
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            onPressed: () => _loadReceiptPreset(sample),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // OCR Extraction Result Card
            if (_isScanning)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF03DAC6)),
                    SizedBox(height: 12),
                    Text('AI Vision OCR is reading line items...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              )
            else ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                gradientColors: const [Color(0xFF22203C), Color(0xFF161528)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMerchant,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatDate(DateTime.now()),
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03DAC6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedCategoryName,
                            style: const TextStyle(
                              color: Color(0xFF03DAC6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    // Line Items Table
                    const Text(
                      'Extracted Line Items',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    ..._items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(item.price),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 24),

                    // Subtotal & Tax Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(Formatters.formatCurrency(_subtotal), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Tax (GST/VAT)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(Formatters.formatCurrency(_tax), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          Formatters.formatCurrency(_total),
                          style: const TextStyle(
                            color: Color(0xFF03DAC6),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text(
                'Assign Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryId == cat.id;
                    return CategoryChip(
                      label: cat.name,
                      icon: cat.parsedIcon,
                      color: cat.parsedColor,
                      isSelected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat.id : null;
                          _selectedCategoryName = cat.name;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              AppButton(
                text: 'Save Bill to Expenses',
                icon: Icons.check_circle_outline,
                isLoading: _isSaved,
                onPressed: _confirmAndSave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
