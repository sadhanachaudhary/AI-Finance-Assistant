/**
 * Enterprise PII & Banking Credential Redactor Service
 * Automatically scrubs sensitive identifiers, card numbers, CVVs, and account details
 * before data is processed by AI models or logged.
 */
export class PiiRedactorService {
  /**
   * Redacts sensitive financial identifiers and credentials from text
   */
  static redact(text: string): string {
    if (!text || typeof text !== 'string') return text;

    let sanitized = text;

    // 1. Credit & Debit Card Numbers (13 to 19 digits, with spaces or hyphens)
    sanitized = sanitized.replace(
      /\b(?:\d{4}[-\s]?){3}\d{4}\b|\b\d{13,19}\b/g,
      (match) => {
        const digits = match.replace(/\D/g, '');
        if (digits.length >= 12 && digits.length <= 19) {
          const last4 = digits.slice(-4);
          return `[CARD ****-${last4}]`;
        }
        return match;
      }
    );

    // 2. CVV / CVC (3-4 digits preceded by cvv/cvc keywords)
    sanitized = sanitized.replace(/(?:cvv|cvc|security\s*code)\s*[:=]?\s*\d{3,4}\b/gi, '[CVV REDACTED]');

    // 3. PINs and Passwords
    sanitized = sanitized.replace(/(?:upi\s*pin|atm\s*pin|pin|password|passwd|pwd)\s*(?:is|[:=])?\s*[\w\d@#$!%*?&]{3,20}\b/gi, '[CREDENTIAL REDACTED]');

    // 4. Aadhaar Numbers (12 digits in 4-4-4 format)
    sanitized = sanitized.replace(/\b\d{4}\s\d{4}\s\d{4}\b/g, '[AADHAAR ****-****-XXXX]');

    // 5. Phone numbers (10 digits) when preceded by phone keywords
    sanitized = sanitized.replace(/(?:phone|mobile|tel|contact)\s*[:=]?\s*(?:\+?91[-\s]?)?[6-9]\d{9}\b/gi, '[PHONE REDACTED]');

    // 6. Bank Account Numbers (preceded by a/c or account)
    sanitized = sanitized.replace(/(?:a\/c|acct|account(?:\s*no)?)\s*[:=]?\s*(\d{4,18})\b/gi, (match, acc) => {
      const last4 = acc.slice(-4);
      return `[ACCOUNT ****-${last4}]`;
    });

    return sanitized;
  }

  /**
   * Sanitizes all fields in user financial ledger context
   */
  static sanitizeContext(ctx: any): any {
    if (!ctx) return ctx;

    const sanitizedExpenses = (ctx.recentExpenses || []).map((e: any) => ({
      ...e,
      merchant: PiiRedactorService.redact(e.merchant || ''),
      notes: e.notes ? PiiRedactorService.redact(e.notes) : null,
    }));

    return {
      ...ctx,
      recentExpenses: sanitizedExpenses,
    };
  }
}
