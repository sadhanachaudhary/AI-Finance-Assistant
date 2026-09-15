class ParsedTransactionResult {
  final double amount;
  final String currency;
  final String merchant;
  final String categoryName;
  final String? maskedAccount;
  final DateTime date;
  final String? notes;
  final bool isSensitiveDiscarded;
  final double confidence;

  const ParsedTransactionResult({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.categoryName,
    this.maskedAccount,
    required this.date,
    this.notes,
    this.isSensitiveDiscarded = false,
    this.confidence = 0.8,
  });

  factory ParsedTransactionResult.discarded() {
    return ParsedTransactionResult(
      amount: 0,
      currency: 'INR',
      merchant: '',
      categoryName: 'Uncategorized',
      date: DateTime.now(),
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
    'mcdonald': 'Food & Dining',
    'domino': 'Food & Dining',
    'kfc': 'Food & Dining',
    'subway': 'Food & Dining',
    'blue tokai': 'Food & Dining',
    'cafe': 'Food & Dining',
    'coffee': 'Food & Dining',
    'dinner': 'Food & Dining',
    'lunch': 'Food & Dining',
    'breakfast': 'Food & Dining',
    'pizza': 'Food & Dining',
    'burger': 'Food & Dining',
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
    'clothes': 'Shopping',
    'shoes': 'Shopping',
    'shopping': 'Shopping',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'rapido': 'Transportation',
    'cab': 'Transportation',
    'auto': 'Transportation',
    'taxi': 'Transportation',
    'shell': 'Transportation',
    'petrol': 'Transportation',
    'fuel': 'Transportation',
    'diesel': 'Transportation',
    'hpcl': 'Transportation',
    'bpcl': 'Transportation',
    'irctc': 'Transportation',
    'metro': 'Transportation',
    'train': 'Transportation',

    // Entertainment
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'hotstar': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'movie': 'Entertainment',
    'cinema': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'youtube': 'Entertainment',

    // Bills & Utilities
    'bescom': 'Bills & Utilities',
    'electricity': 'Bills & Utilities',
    'water': 'Bills & Utilities',
    'broadband': 'Bills & Utilities',
    'wifi': 'Bills & Utilities',
    'airtel': 'Bills & Utilities',
    'jio': 'Bills & Utilities',
    'rent': 'Bills & Utilities',
    'maintenance': 'Bills & Utilities',
    'icloud': 'Bills & Utilities',

    // Health & Fitness
    'cult': 'Health & Fitness',
    'gym': 'Health & Fitness',
    'apollo': 'Health & Fitness',
    'pharmeasy': 'Health & Fitness',
    'pharmacy': 'Health & Fitness',
    'medicine': 'Health & Fitness',
    'doctor': 'Health & Fitness',
    'hospital': 'Health & Fitness',

    // Groceries
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'instamart': 'Groceries',
    'bigbasket': 'Groceries',
    'whole foods': 'Groceries',
    'grocery': 'Groceries',
    'groceries': 'Groceries',
    'vegetables': 'Groceries',
    'fruits': 'Groceries',
    'milk': 'Groceries',

    // Travel
    'indigo': 'Travel',
    'air india': 'Travel',
    'flight': 'Travel',
    'hotel': 'Travel',
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

  /// On-device privacy-first parser supporting bank SMS and natural language statements
  static ParsedTransactionResult? parse(String text) {
    if (text.trim().isEmpty) return null;

    // Strict privacy barrier
    if (isSensitiveOtp(text)) {
      return ParsedTransactionResult.discarded();
    }

    final cleanText = text.trim();
    final lower = cleanText.toLowerCase();

    // 1. Amount Extraction (supports ₹450, 4.5k, 10k, Rs 450, 450 inr, etc.)
    double? amount;
    final kRegex = RegExp(r'(?:rs\.?|inr|₹|\$)?\s*([0-9]+(?:\.[0-9]+)?)\s*k\b', caseSensitive: false);
    final kMatch = kRegex.firstMatch(cleanText);

    if (kMatch != null) {
      amount = double.tryParse(kMatch.group(1)!) != null ? double.parse(kMatch.group(1)!) * 1000 : null;
    } else {
      final amountRegex = RegExp(r'(?:rs\.?|inr|₹|\$|€|£)\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final altAmountRegex = RegExp(r'\b([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)\s*(?:rs|inr|rupees|bucks)\b', caseSensitive: false);
      final verbAmountRegex = RegExp(r'(?:spent|paid|for|cost|debited)\s+([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final genericNumRegex = RegExp(r'\b([0-9]{2,7}(?:\.[0-9]{1,2})?)\b');

      final match = amountRegex.firstMatch(cleanText) ??
          altAmountRegex.firstMatch(cleanText) ??
          verbAmountRegex.firstMatch(cleanText) ??
          genericNumRegex.firstMatch(cleanText);

      if (match != null) {
        final rawAmountStr = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(rawAmountStr);
      }
    }

    if (amount == null || amount <= 0) return null;

    // 2. Currency detection
    String currency = 'INR';
    if (cleanText.contains('\$') || lower.contains('usd') || lower.contains('dollars')) {
      currency = 'USD';
    } else if (cleanText.contains('€') || lower.contains('eur')) {
      currency = 'EUR';
    } else if (cleanText.contains('£') || lower.contains('gbp')) {
      currency = 'GBP';
    }

    // 3. Masked account/card
    final accountRegex = RegExp(r'(?:a\/c|acct|account|card|ending (?:in )?)\s*(?:[xX*]+)?([0-9]{3,4})', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(cleanText);
    final maskedAccount = accountMatch != null ? 'XX${accountMatch.group(1)}' : null;

    // 4. Relative Date Extraction
    var targetDate = DateTime.now();
    if (lower.contains('yesterday') || lower.contains('last night')) {
      targetDate = targetDate.subtract(const Duration(days: 1));
    } else if (lower.contains('day before yesterday')) {
      targetDate = targetDate.subtract(const Duration(days: 2));
    }

    // 5. Merchant & Category Detection
    String merchant = 'Expense';
    String category = 'Shopping';
    double confidence = 0.7;

    for (final entry in _merchantCategories.entries) {
      if (lower.contains(entry.key)) {
        merchant = _capitalize(entry.key);
        category = entry.value;
        confidence = 0.95;
        break;
      }
    }

    // Conversational extraction for merchant name
    if (merchant == 'Expense') {
      final merchantPattern = RegExp(r'(?:to|towards|at|paid to|from)\s+([A-Za-z0-9\s&]{2,22}?)(?:\s+(?:on|ref|via|for|today|yesterday)|\.|$)', caseSensitive: false);
      final match = merchantPattern.firstMatch(cleanText);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (!RegExp(r'^(the|a|an|my|your|a\/c|account|card|bank|upi|cash)$', caseSensitive: false).hasMatch(candidate)) {
          merchant = _capitalize(candidate);
        }
      }
    }

    // 6. Notes extraction
    String? notes;
    final forMatch = RegExp(r'(?:for|on|regarding)\s+([A-Za-z0-9\s,]{3,30}?)(?:\s+(?:today|yesterday|via|with|at)|\.|$)', caseSensitive: false).firstMatch(cleanText);
    if (forMatch != null && forMatch.group(1) != null) {
      final noteCandidate = forMatch.group(1)!.trim();
      if (noteCandidate.toLowerCase() != merchant.toLowerCase()) {
        notes = noteCandidate;
      }
    }

    return ParsedTransactionResult(
      amount: amount,
      currency: currency,
      merchant: merchant,
      categoryName: category,
      maskedAccount: maskedAccount,
      date: targetDate,
      notes: notes,
      confidence: confidence,
    );
  }

  static String _capitalize(String input) {
    return input.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
