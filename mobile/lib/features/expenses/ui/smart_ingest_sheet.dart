import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    {
      'label': '🔒 OTP Demo',
      'text': 'Your OTP for banking login is 492104. Do not share your OTP or password with anyone.',
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
        _amountController.clear();
        _merchantController.clear();
      });
      return;
    }

    // Match category
    final categories = ref.read(categoriesProvider).value ?? [];
    Category? matchedCat;
    try {
      matchedCat = categories.firstWhere(
        (c) => c.name.toLowerCase() == parsed.categoryName.toLowerCase(),
      );
    } catch (_) {
      matchedCat = categories.isNotEmpty ? categories.first : null;
    }

    setState(() {
      _isOtpBlocked = false;
      _isParsed = true;
      _amountController.text = parsed.amount.toStringAsFixed(2);
      _merchantController.text = parsed.merchant;
      _maskedAccount = parsed.maskedAccount;
      _notesController.text = parsed.maskedAccount != null ? 'Via account ${parsed.maskedAccount}' : 'Auto-detected via alert';
      if (matchedCat != null) {
        _selectedCategoryId = matchedCat.id;
      }
    });
  }

  void _applySample(String sampleText) {
    _textController.text = sampleText;
    _onTextUpdated(sampleText);
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(expensesProvider.notifier).addExpense(
            amount: amount,
            date: DateTime.now(),
            merchant: _merchantController.text.trim().isNotEmpty ? _merchantController.text.trim() : 'Expense',
            notes: _notesController.text.trim(),
            categoryId: _selectedCategoryId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Logged ₹${amount.toStringAsFixed(2)} for ${_merchantController.text}!'),
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
            content: Text('Failed to save expense: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          mainAxisSize: MainAxisSize.min,
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
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Spending Ingest',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Privacy-First Bank Alert & SMS Parser',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy Guarantee Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF03DAC6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF03DAC6).withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFF03DAC6), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'On-Device Processing: Sensitive credentials & OTPs are discarded immediately. Only amount & merchant metadata are logged.',
                      style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset Test Buttons (Clickable)
            const Text(
              'Test with Sample Bank Alerts:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleAlerts.map((sample) {
                  final isOtp = sample['label']!.contains('OTP');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: isOtp ? const Color(0xFFFF5252).withValues(alpha: 0.15) : const Color(0xFF222232),
                      side: BorderSide(
                        color: isOtp ? const Color(0xFFFF5252).withValues(alpha: 0.4) : const Color(0xFF323248),
                      ),
                      label: Text(
                        sample['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isOtp ? const Color(0xFFFF5252) : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _applySample(sample['text']!),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Text Input Box (Paste or type bank SMS / alert)
            AppTextField(
              controller: _textController,
              labelText: 'Paste Bank Alert / Transaction SMS',
              hintText: 'e.g. Rs 450 debited from A/c XX1234 towards Swiggy...',
              prefixIcon: Icons.sms_outlined,
              maxLines: 3,
              onChanged: _onTextUpdated,
            ),
            const SizedBox(height: 16),

            // OTP Blocked Alert
            if (_isOtpBlocked)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block_rounded, color: Color(0xFFFF5252), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensitive OTP Detected & Discarded',
                            style: TextStyle(
                              color: Color(0xFFFF5252),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'For your safety, the app refuses to read or store one-time passwords.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Parsed Live Card
            if (_isParsed) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                gradientColors: const [Color(0xFF242242), Color(0xFF161528)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF03DAC6), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Auto-Detected Expense',
                              style: TextStyle(color: Color(0xFF03DAC6), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (_maskedAccount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _maskedAccount!,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Amount & Merchant fields
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: _amountController,
                            labelText: 'Amount (₹)',
                            hintText: '0.00',
                            prefixIcon: Icons.currency_rupee,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: AppTextField(
                            controller: _merchantController,
                            labelText: 'Merchant',
                            hintText: 'Store / Merchant Name',
                            prefixIcon: Icons.storefront_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category selection
                    const Text(
                      'Category (Auto-Assigned)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
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
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    AppTextField(
                      controller: _notesController,
                      labelText: 'Notes',
                      hintText: 'Add note...',
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              AppButton(
                text: 'Confirm & Log Expense',
                icon: Icons.check_circle_outline,
                isLoading: _isLoading,
                onPressed: _saveExpense,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
