import { PiiRedactorService } from '../services/pii-redactor.service';

describe('PiiRedactorService Unit Tests', () => {
  test('Redacts 16-digit credit card numbers, preserving only last 4 digits', () => {
    const input = 'Paid using card 4532 1100 8899 1234 at Starbucks';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toBe('Paid using card [CARD ****-1234] at Starbucks');
  });

  test('Redacts unspaced continuous 16-digit card numbers', () => {
    const input = 'Card number 4111222233334444 charged $45';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toBe('Card number [CARD ****-4444] charged $45');
  });

  test('Redacts CVV and security codes', () => {
    const input = 'CVV: 456 and security code: 789';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toContain('[CVV REDACTED]');
    expect(redacted).not.toContain('456');
    expect(redacted).not.toContain('789');
  });

  test('Redacts UPI pins and passwords', () => {
    const input = 'My upi pin is 987654 and password is supersecret123';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toContain('[CREDENTIAL REDACTED]');
    expect(redacted).not.toContain('987654');
    expect(redacted).not.toContain('supersecret123');
  });

  test('Redacts Aadhaar numbers', () => {
    const input = 'Aadhaar 1234 5678 9012 verified';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toBe('Aadhaar [AADHAAR ****-****-XXXX] verified');
  });

  test('Redacts Bank Account Numbers', () => {
    const input = 'Transfer from A/C 9876543210 to vendor';
    const redacted = PiiRedactorService.redact(input);
    expect(redacted).toBe('Transfer from [ACCOUNT ****-3210] to vendor');
  });

  test('Sanitizes ledger context object safely', () => {
    const context = {
      user: 'Test',
      recentExpenses: [
        { merchant: 'Card 4532-1100-8899-9988 Payment', notes: 'pin: 1234' },
      ],
    };

    const sanitized = PiiRedactorService.sanitizeContext(context);
    expect(sanitized.recentExpenses[0].merchant).toContain('[CARD ****-9988]');
    expect(sanitized.recentExpenses[0].notes).toBe('[CREDENTIAL REDACTED]');
  });
});
