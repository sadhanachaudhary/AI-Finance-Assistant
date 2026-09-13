class ParsedTransactionResult {
  final double amount;
  final String currency;
  final String merchant;
  final String categoryName;
  final String? maskedAccount;
  final bool isSensitiveDiscarded;
  final double confidence;

  const ParsedTransactionResult({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.categoryName,
    this.maskedAccount,
    this.isSensitiveDiscarded = false,
    this.confidence = 0.8,
  });

  factory ParsedTransactionResult.discarded() {
    return const ParsedTransactionResult(
      amount: 0,
      currency: 'INR',
      merchant: '',
      categoryName: 'Uncategorized',
      isSensitiveDiscarded: true,
      confidence: 0,
    );
  }
}

class SmartTransactionParser {
  static const Map<String, String> _merchantCategories = {
    // Food & Dining
    'swiggy': 'Food & Dining',
    'zomato': 'Food & Dining',
    'starbucks': 'Food & Dining',
    'mcdonalds': 'Food & Dining',
    'dominos': 'Food & Dining',
    'kfc': 'Food & Dining',
    'subway': 'Food & Dining',
    'blue tokai': 'Food & Dining',
    'cafe': 'Food & Dining',
    'restaurant': 'Food & Dining',

    // Shopping
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'zara': 'Shopping',
    'h&m': 'Shopping',
    'nykaa': 'Shopping',
    'ajio': 'Shopping',
    'apple': 'Shopping',
    'croma': 'Shopping',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'rapido': 'Transportation',
    'shell': 'Transportation',
    'petrol': 'Transportation',
    'fuel': 'Transportation',
    'hpcl': 'Transportation',
    'bpcl': 'Transportation',
    'irctc': 'Transportation',
    'metro': 'Transportation',

    // Entertainment
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'hotstar': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'youtube': 'Entertainment',

    // Bills & Utilities
    'bescom': 'Bills & Utilities',
    'electricity': 'Bills & Utilities',
    'water': 'Bills & Utilities',
    'broadband': 'Bills & Utilities',
    'airtel': 'Bills & Utilities',
    'jio': 'Bills & Utilities',
    'icloud': 'Bills & Utilities',

    // Health & Fitness
    'cult': 'Health & Fitness',
    'gym': 'Health & Fitness',
    'apollo': 'Health & Fitness',
    'pharmeasy': 'Health & Fitness',
    'pharmacy': 'Health & Fitness',
    'hospital': 'Health & Fitness',

    // Groceries
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'instamart': 'Groceries',
    'bigbasket': 'Groceries',
    'whole foods': 'Groceries',

    // Travel
    'indigo': 'Travel',
    'air india': 'Travel',
    'makemytrip': 'Travel',
    'cleartrip': 'Travel',
    'booking.com': 'Travel',
    'airbnb': 'Travel',
  };

  /// Check if text is a sensitive OTP or security code
  static bool isSensitiveOtp(String text) {
    final lower = text.toLowerCase();
    final sensitiveKeywords = [
      'otp',
      'one time password',
      'verification code',
      'security code',
      'login code',
      'do not share your otp',
      'do not share your password',
      'secret code',
    ];

    for (final kw in sensitiveKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  /// On-device privacy-first parser
  static ParsedTransactionResult? parse(String text) {
    if (text.trim().isEmpty) return null;

    // Strict privacy barrier
    if (isSensitiveOtp(text)) {
      return ParsedTransactionResult.discarded();
    }

    final cleanText = text.trim();

    // 1. Amount Extraction
    final amountRegex = RegExp(r'(?:rs\.?|inr|₹|\$|€|£)\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(cleanText);

    if (amountMatch == null) return null;

    final rawAmountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmountStr);
    if (amount == null || amount <= 0) return null;

    // 2. Currency detection
    String currency = 'INR';
    if (cleanText.contains('\$')) {
      currency = 'USD';
    } else if (cleanText.contains('€') || cleanText.toUpperCase().contains('EUR')) {
      currency = 'EUR';
    } else if (cleanText.contains('£') || cleanText.toUpperCase().contains('GBP')) {
      currency = 'GBP';
    }

    // 3. Masked account/card
    final accountRegex = RegExp(r'(?:a\/c|acct|account|card|ending (?:in )?)\s*(?:[xX*]+)?([0-9]{3,4})', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(cleanText);
    final maskedAccount = accountMatch != null ? 'XX${accountMatch.group(1)}' : null;

    // 4. Merchant & Category Detection
    String merchant = 'Expense';
    String category = 'Shopping';
    double confidence = 0.7;

    final lower = cleanText.toLowerCase();
    for (final entry in _merchantCategories.entries) {
      if (lower.contains(entry.key)) {
        merchant = _capitalize(entry.key);
        category = entry.value;
        confidence = 0.95;
        break;
      }
    }

    // Heuristic fallback for merchant name if not in known map
    if (merchant == 'Expense') {
      final merchantPattern = RegExp(r'(?:to|towards|at|paid to)\s+([A-Za-z0-9\s&]{3,20}?)(?:\s+on|\s+ref|\s+via|\.|$)', caseSensitive: false);
      final match = merchantPattern.firstMatch(cleanText);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (!RegExp(r'^(your|a\/c|account|card|bank|upi)$', caseSensitive: false).hasMatch(candidate)) {
          merchant = _capitalize(candidate);
        }
      }
    }

    return ParsedTransactionResult(
      amount: amount,
      currency: currency,
      merchant: merchant,
      categoryName: category,
      maskedAccount: maskedAccount,
      confidence: confidence,
    );
  }

  static String _capitalize(String input) {
    return input.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
