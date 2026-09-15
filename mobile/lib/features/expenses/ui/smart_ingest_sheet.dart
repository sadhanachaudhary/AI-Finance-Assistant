import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/category_chip.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../services/smart_transaction_parser.dart';

class SmartIngestSheet extends ConsumerStatefulWidget {
  const SmartIngestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmartIngestSheet(),
    );
  }

  @override
  ConsumerState<SmartIngestSheet> createState() => _SmartIngestSheetState();
}

class _SmartIngestSheetState extends ConsumerState<SmartIngestSheet> {
  final _textController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _maskedAccount;
  bool _isOtpBlocked = false;
  bool _isParsed = false;
  bool _isLoading = false;

  final List<Map<String, String>> _sampleAlerts = [
    {
      'label': '🍔 Swiggy UPI',
      'text': 'Rs 450.00 debited from A/c XX4921 towards Swiggy on 13-Sep via UPI ref 92837482',
    },
    {
      'label': '🛍️ Amazon Card',
      'text': 'INR 2,499.00 spent on your ICICI Card ending 8812 at Amazon Marketplace on 13-Sep',
    },
    {
      'label': '🚗 Uber Trip',
      'text': 'Paid Rs 320.00 to Uber India via Google Pay from A/c XX1234',
    },
    {
      'label': '☕ Starbucks',
      'text': 'Purchase of Rs 550.00 at Starbucks Cafe with HDFC Bank Debit Card XX9910',
    },
    {
      'label': '🎬 Netflix',
      'text': 'Autopay of Rs 649.00 debited towards Netflix Entertainment from A/c XX4921',
    },
    {
      'label': '⛽ Shell Petrol',
      'text': 'Debited INR 1,800.00 for fuel at Shell Petrol Station via UPI',
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTextUpdated(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _isParsed = false;
        _isOtpBlocked = false;
        _maskedAccount = null;
      });
      return;
    }

    final parsed = SmartTransactionParser.parse(input);

    if (parsed == null) {
      setState(() {
        _isParsed = false;
        _isOtpBlocked = false;
      });
      return;
    }

    if (parsed.isSensitiveDiscarded) {
      setState(() {
        _isOtpBlocked = true;
        _isParsed = false;
      });
      return;
    }

    final categories = ref.read(categoriesProvider).value ?? [];
    String? matchedCatId;
    for (final c in categories) {
      if (c.name.toLowerCase() == parsed.categoryName.toLowerCase()) {
        matchedCatId = c.id;
        break;
      }
    }

    setState(() {
      _isOtpBlocked = false;
      _isParsed = true;
      _amountController.text = parsed.amount.toStringAsFixed(0);
      _merchantController.text = parsed.merchant;
      _maskedAccount = parsed.maskedAccount;
      _selectedCategoryId = matchedCatId ?? (categories.isNotEmpty ? categories.first.id : null);
      _notesController.text = parsed.maskedAccount != null ? 'Via A/c ${parsed.maskedAccount}' : '';
    });
  }

  Future<void> _saveParsedExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(expensesProvider.notifier).addExpense(
            amount: amount,
            date: DateTime.now(),
            merchant: _merchantController.text.trim(),
            notes: _notesController.text.trim(),
            categoryId: _selectedCategoryId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryPurple,
            content: Text('🎉 Ingested ${parsedCurrency(_merchantController.text)} expense!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.outflowCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String parsedCurrency(String merchant) => merchant.isNotEmpty ? merchant : 'Smart';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
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
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Smart SMS Ingestion',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Paste any bank SMS or transaction notification. Sensitive OTPs are automatically scrubbed.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Quick Sample Pills
            const Text('Test with bank alert samples:', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleAlerts.map((sample) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(sample['label']!),
                      backgroundColor: AppTheme.surfaceElevated,
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      onPressed: () {
                        _textController.text = sample['text']!;
                        _onTextUpdated(sample['text']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Paste Input Field
            TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              onChanged: _onTextUpdated,
              decoration: InputDecoration(
                hintText: 'Paste bank SMS or transaction alert here...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13.5),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),
            // Discarded OTP Alert
            if (_isOtpBlocked)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.softRedBadge,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.outflowCoral, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🛡️ Sensitive OTP Detected: Discarded automatically to protect your privacy.',
                        style: TextStyle(color: AppTheme.outflowCoral, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Parsed Result Card
            if (_isParsed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.softGreenBadge,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.inflowGreen, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Parsed Transaction Ready',
                          style: TextStyle(color: AppTheme.inflowGreen, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _amountController,
                            labelText: 'Amount (₹)',
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _merchantController,
                            labelText: 'Merchant',
                            hintText: 'Merchant',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (categories.isNotEmpty) ...[
                      const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = _selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: CategoryChip(
                                label: cat.name,
                                icon: cat.parsedIcon,
                                color: cat.parsedColor,
                                isSelected: isSelected,
                                onSelected: (s) => setState(() => _selectedCategoryId = s ? cat.id : null),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Save Ingested Expense',
                onPressed: _saveParsedExpense,
                isLoading: _isLoading,
                icon: Icons.check_rounded,
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
