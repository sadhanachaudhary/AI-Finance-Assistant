export interface ParsedTransaction {
  amount: number;
  currency: string;
  merchant: string;
  categoryName: string;
  maskedAccount?: string;
  isDebit: boolean;
  date?: string;
  confidence: number;
  privacySafe: boolean;
  rawStripped: boolean;
}

// Known merchant -> Category mapping
const MERCHANT_CATEGORY_MAP: Record<string, string> = {
  // Food & Dining
  swiggy: 'Food & Dining',
  zomato: 'Food & Dining',
  starbucks: 'Food & Dining',
  mcdonalds: 'Food & Dining',
  dominos: 'Food & Dining',
  kfc: 'Food & Dining',
  subway: 'Food & Dining',
  dunkin: 'Food & Dining',
  'blue tokai': 'Food & Dining',
  restaurant: 'Food & Dining',
  cafe: 'Food & Dining',
  barista: 'Food & Dining',

  // Shopping
  amazon: 'Shopping',
  flipkart: 'Shopping',
  myntra: 'Shopping',
  zara: 'Shopping',
  hm: 'Shopping',
  ikea: 'Shopping',
  nykaa: 'Shopping',
  ajio: 'Shopping',
  apple: 'Shopping',
  croma: 'Shopping',
  reliance: 'Shopping',

  // Transportation
  uber: 'Transportation',
  ola: 'Transportation',
  rapido: 'Transportation',
  shell: 'Transportation',
  petrol: 'Transportation',
  fuel: 'Transportation',
  hpcl: 'Transportation',
  bpcl: 'Transportation',
  ioc: 'Transportation',
  irctc: 'Transportation',
  metro: 'Transportation',
  toll: 'Transportation',
  fastag: 'Transportation',

  // Entertainment
  netflix: 'Entertainment',
  spotify: 'Entertainment',
  hotstar: 'Entertainment',
  pvr: 'Entertainment',
  inox: 'Entertainment',
  bookmyshow: 'Entertainment',
  prime: 'Entertainment',
  youtube: 'Entertainment',
  cinema: 'Entertainment',

  // Bills & Utilities
  bescom: 'Bills & Utilities',
  electricity: 'Bills & Utilities',
  water: 'Bills & Utilities',
  broadband: 'Bills & Utilities',
  airtel: 'Bills & Utilities',
  jio: 'Bills & Utilities',
  vi: 'Bills & Utilities',
  gas: 'Bills & Utilities',
  recharge: 'Bills & Utilities',
  icloud: 'Bills & Utilities',
  google: 'Bills & Utilities',

  // Health & Fitness
  cult: 'Health & Fitness',
  gym: 'Health & Fitness',
  pharmacy: 'Health & Fitness',
  apollo: 'Health & Fitness',
  pharmeasy: 'Health & Fitness',
  hospital: 'Health & Fitness',
  practo: 'Health & Fitness',
  fitness: 'Health & Fitness',

  // Groceries
  blinkit: 'Groceries',
  zepto: 'Groceries',
  instamart: 'Groceries',
  bigbasket: 'Groceries',
  supermarket: 'Groceries',
  mart: 'Groceries',
  'whole foods': 'Groceries',

  // Travel
  indigo: 'Travel',
  airindia: 'Travel',
  makemytrip: 'Travel',
  cleartrip: 'Travel',
  booking: 'Travel',
  airbnb: 'Travel',
  hotel: 'Travel',
  flight: 'Travel',
};

export class SmartParserService {
  /**
   * Sanitizes input text and rejects messages containing sensitive OTPs or security codes.
   */
  static isSensitiveOtpMessage(text: string): boolean {
    const sensitivePatterns = [
      /\b(otp|one time password|verification code|security code|login code)\b/i,
      /\bdo not share (your )?(otp|password|pin|code)\b/i,
      /\bsecret code\b/i,
      /\bauth code\b/i,
    ];

    return sensitivePatterns.some((pattern) => pattern.test(text));
  }

  /**
   * Parses raw SMS / transaction notification string safely.
   */
  static parseTransactionText(text: string): ParsedTransaction | null {
    if (!text || typeof text !== 'string') return null;

    // 1. Strict Privacy Check: Discard OTP messages
    if (this.isSensitiveOtpMessage(text)) {
      return null;
    }

    const cleanText = text.trim();

    // 2. Amount & Currency Detection
    // Matches: Rs. 450, INR 450.00, ₹450, $45.00, EUR 30.50
    const amountRegex = /(?:rs\.?|inr|₹|\$|€|£)\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)/i;
    const amountMatch = cleanText.match(amountRegex);

    let amount = 0;
    let currency = 'INR';

    if (amountMatch) {
      amount = parseFloat(amountMatch[1].replace(/,/g, ''));
      if (cleanText.includes('$')) currency = 'USD';
      else if (cleanText.includes('€') || /eur/i.test(cleanText)) currency = 'EUR';
      else if (cleanText.includes('£') || /gbp/i.test(cleanText)) currency = 'GBP';
      else currency = 'INR';
    }

    if (amount <= 0) return null;

    // 3. Masked Account / Card reference
    // Matches: A/c XX1234, card ending in 4321, etc.
    const accountRegex = /(?:a\/c|acct|account|card|ending (?:in )?)\s*(?:[xX*]+)?([0-9]{3,4})/i;
    const accountMatch = cleanText.match(accountRegex);
    const maskedAccount = accountMatch ? `XX${accountMatch[1]}` : undefined;

    // 4. Merchant Identification
    let merchant = 'Expense';
    let detectedCategory = 'Shopping';
    let confidence = 0.6;

    // Look for merchant keywords after "to", "at", "towards", "vpa", "info:"
    const merchantKeywords = [
      /(?:to|towards|at|vpa|info[:\s]|paid to)\s+([A-Za-z0-9\s&'-]{3,25}?)(?:\s+on|\s+ref|\s+upi|\s+via|\.|$)/i,
      /(?:spent on|purchase at)\s+([A-Za-z0-9\s&'-]{3,25}?)(?:\s+on|\.|$)/i,
    ];

    for (const pattern of merchantKeywords) {
      const match = cleanText.match(pattern);
      if (match && match[1]) {
        const candidate = match[1].trim();
        // Ignore generic words
        if (!/^(your|a\/c|account|card|bank|upi|ref|inr|rs)$/i.test(candidate)) {
          merchant = candidate;
          break;
        }
      }
    }

    // Direct brand matching in text
    const lowerText = cleanText.toLowerCase();
    for (const [brand, category] of Object.entries(MERCHANT_CATEGORY_MAP)) {
      if (lowerText.includes(brand)) {
        merchant = brand.charAt(0).toUpperCase() + brand.slice(1);
        detectedCategory = category;
        confidence = 0.95;
        break;
      }
    }

    // Capitalize merchant name nicely
    merchant = merchant
      .split(' ')
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    return {
      amount,
      currency,
      merchant,
      categoryName: detectedCategory,
      maskedAccount,
      isDebit: true,
      confidence,
      privacySafe: true,
      rawStripped: true,
    };
  }

  /**
   * Categorizes a merchant name or description.
   */
  static categorize(merchant: string, notes?: string): string {
    const combined = `${merchant || ''} ${notes || ''}`.toLowerCase();

    for (const [keyword, category] of Object.entries(MERCHANT_CATEGORY_MAP)) {
      if (combined.includes(keyword)) {
        return category;
      }
    }

    return 'Shopping';
  }
}
