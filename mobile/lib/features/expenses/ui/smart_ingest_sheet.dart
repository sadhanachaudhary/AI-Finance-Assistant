import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../auth/providers/auth_provider.dart';
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

  int _selectedMode = 0; // 0 = Conversational / Natural Language, 1 = Bank SMS
  String? _selectedCategoryId;
  String? _maskedAccount;
  DateTime _transactionDate = DateTime.now();
  bool _isOtpBlocked = false;
  bool _isParsed = false;
  bool _isLoading = false;
  bool _isAiParsing = false;

  final List<Map<String, String>> _conversationalSamples = [
    {
      'label': '☕ Starbucks Coffee',
      'text': 'Spent 450 at Starbucks for cold brew coffee today',
    },
    {
      'label': '🍔 Swiggy Dinner',
      'text': 'Ordered 890 Swiggy dinner with friends yesterday',
    },
    {
      'label': '🚗 Uber Commute',
      'text': 'Paid 320 for Uber ride to office',
    },
    {
      'label': '🛍️ Zara Shopping',
      'text': '4.5k shopping at Zara store today',
    },
    {
      'label': '🎬 Netflix Sub',
      'text': '649 for Netflix monthly subscription',
    },
    {
      'label': '🥦 Blinkit Groceries',
      'text': 'Spent 1,250 on Blinkit groceries this morning',
    },
  ];

  final List<Map<String, String>> _bankSmsAlerts = [
    {
      'label': '💳 HDFC Alert',
      'text': 'Rs 3,499.00 spent on your HDFC Bank Card ending 4092 at Amazon Marketplace on 15-Sep. Avl bal: Rs 42,100.',
    },
    {
      'label': '🏦 ICICI UPI',
      'text': 'Rs 450.00 debited from A/c XX4921 towards Swiggy on 14-Sep via UPI ref 92837482',
    },
    {
      'label': '🏧 SBI Card',
      'text': 'INR 1,800.00 spent on SBI Card ending 1289 at Shell Petrol Station on 13-Sep',
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
      _transactionDate = parsed.date;
      _amountController.text = parsed.amount.toStringAsFixed(0);
      _merchantController.text = parsed.merchant;
      _maskedAccount = parsed.maskedAccount;
      _selectedCategoryId = matchedCatId ?? (categories.isNotEmpty ? categories.first.id : null);
      _notesController.text = parsed.notes ?? (parsed.maskedAccount != null ? 'Via A/c ${parsed.maskedAccount}' : '');
    });
  }

  Future<void> _triggerCloudAiParse() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAiParsing = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.dio.post(
        ApiEndpoints.aiParseExpense,
        data: {'text': text},
      );

      if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
        final parsed = res.data['data']['parsed'];
        if (parsed != null && parsed['amount'] != null && (parsed['amount'] as num) > 0) {
          final categories = ref.read(categoriesProvider).value ?? [];
          final categoryName = parsed['categoryName'] ?? 'Shopping';
          String? catId = parsed['categoryId'];

          if (catId == null) {
            final match = categories.where((c) => c.name.toLowerCase() == categoryName.toString().toLowerCase()).firstOrNull;
            catId = match?.id;
          }

          setState(() {
            _isParsed = true;
            _isOtpBlocked = false;
            _amountController.text = (parsed['amount'] as num).toStringAsFixed(0);
            _merchantController.text = parsed['merchant'] ?? 'Expense';
            _selectedCategoryId = catId ?? (categories.isNotEmpty ? categories.first.id : null);
            _notesController.text = parsed['notes'] ?? '';
            if (parsed['date'] != null) {
              _transactionDate = DateTime.tryParse(parsed['date']) ?? DateTime.now();
            }
          });
          return;
        }
      }
    } catch (_) {
      // Fallback to on-device parser
      _onTextUpdated(text);
    } finally {
      if (mounted) setState(() => _isAiParsing = false);
    }
  }

  Future<void> _saveParsedExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(expensesProvider.notifier).addExpense(
            amount: amount,
            date: _transactionDate,
            merchant: _merchantController.text.trim(),
            notes: _notesController.text.trim(),
            categoryId: _selectedCategoryId,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryPurple,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Added ₹${amount.toStringAsFixed(0)} for ${_merchantController.text.trim()}!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: AppTheme.outflowCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final samples = _selectedMode == 0 ? _conversationalSamples : _bankSmsAlerts;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
                      'Smart Ingest (NLP)',
                      style: TextStyle(
                        fontSize: 18,
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
            const SizedBox(height: 12),

            // Mode Selector: Natural Language vs Bank SMS
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMode = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedMode == 0
                              ? [
                                  const BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '🗣️ Conversational',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedMode == 0 ? AppTheme.primaryPurple : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMode = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedMode == 1
                              ? [
                                  const BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '📩 Bank SMS / UPI',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedMode == 1 ? AppTheme.primaryPurple : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Quick Samples Carousel
            Text(
              _selectedMode == 0 ? 'Try conversational prompts:' : 'Try bank SMS alerts:',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: samples.map((sample) {
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

            // Input Text Field
            TextField(
              controller: _textController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              onChanged: _onTextUpdated,
              decoration: InputDecoration(
                hintText: _selectedMode == 0
                    ? 'e.g. "Spent 450 at Starbucks on coffee today"'
                    : 'Paste bank SMS or transaction notification here...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                suffixIcon: _isAiParsing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 20),
                        tooltip: 'Deep AI Parse',
                        onPressed: _triggerCloudAiParse,
                      ),
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
                margin: const EdgeInsets.only(bottom: 12),
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
              const SizedBox(height: 18),
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
