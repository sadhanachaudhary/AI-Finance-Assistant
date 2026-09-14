import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/providers/expense_provider.dart';
import '../../features/expenses/services/smart_transaction_parser.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../shared/providers/security_provider.dart';

final smsListenerServiceProvider = Provider<SmsListenerService>((ref) {
  return SmsListenerService(ref);
});

class SmsListenerService {
  final Ref _ref;
  bool _isListening = false;

  SmsListenerService(this._ref);

  bool get isListening => _isListening;

  /**
   * Initializes on-device SMS stream listener with strict privacy controls.
   */
  void initialize() {
    final sec = _ref.read(securityProvider);
    if (!sec.onDeviceOnly) return;

    _isListening = true;
  }

  /**
   * Processes incoming raw SMS string on-device.
   * Discards OTPs, scrubs card numbers, extracts expense, and logs it.
   */
  Future<bool> processIncomingSms(String rawSms, {BuildContext? context}) async {
    final sec = _ref.read(securityProvider);

    // If on-device parsing or OTP shield is active, parse strictly locally
    final parsed = SmartTransactionParser.parse(rawSms);

    if (parsed == null || parsed.isSensitiveDiscarded || parsed.amount <= 0) {
      // Message was an OTP, 2FA code, or non-financial alert -> safely discarded
      return false;
    }

    try {
      final categories = _ref.read(categoriesProvider).value ?? [];
      String? categoryId;

      try {
        final match = categories.firstWhere(
          (c) => c.name.toLowerCase() == parsed.categoryName.toLowerCase(),
        );
        categoryId = match.id;
      } catch (_) {
        if (categories.isNotEmpty) {
          categoryId = categories.first.id;
        }
      }

      // Add expense directly to user's ledger
      await _ref.read(expensesProvider.notifier).addExpense(
            amount: parsed.amount,
            date: DateTime.now(),
            merchant: parsed.merchant,
            notes: 'Auto-Ingested: ${parsed.maskedAccount != null ? 'A/c ${parsed.maskedAccount}' : 'UPI/Card'}',
            categoryId: categoryId,
          );

      // Trigger instant smart alerts re-evaluation
      _ref.read(notificationsProvider.notifier).generateSmartAlerts();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ Auto-Logged: ₹${parsed.amount.toStringAsFixed(2)} at ${parsed.merchant} (${parsed.categoryName})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
