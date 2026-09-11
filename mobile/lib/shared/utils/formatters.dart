class Formatters {
  /// Formats a number as currency (e.g. ₹1,250.00 or $1,250.00)
  static String formatCurrency(double amount, {String currency = 'INR'}) {
    final symbol = currency == 'INR' ? '₹' : (currency == 'USD' ? '$' : '$currency ');
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    // Custom formatted currency with commas for thousands
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
      } else if (count > 3 && (count - 3) % 2 == 0 && i > 0) {
        // Indian number system format (2,2,3) or western standard
        buffer.write(',');
      }
    }
    
    final formattedInt = buffer.toString().split('').reversed.join('');
    final formattedValue = '$symbol$formattedInt.$decimalPart';
    return isNegative ? '-$formattedValue' : formattedValue;
  }

  /// Formats a DateTime object into a human-readable string (e.g. "Today, 2:30 PM", "12 Oct 2026")
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != date.day)) {
      return 'Yesterday';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Formats a percentage change (e.g. "+12.5%", "-3.2%")
  static String formatPercentage(double percent) {
    final prefix = percent > 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(1)}%';
  }
}
