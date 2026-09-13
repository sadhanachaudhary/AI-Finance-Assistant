class Formatters {
  /// Formats a number as currency (e.g. ₹1,250.00 or $1,250.00)
  static String formatCurrency(double amount, {String currency = 'INR'}) {
    final String symbol;
    switch (currency.toUpperCase()) {
      case 'INR':
        symbol = '₹';
        break;
      case 'USD':
        symbol = r'$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'AED':
        symbol = 'AED ';
        break;
      case 'CAD':
        symbol = r'CA$';
        break;
      case 'JPY':
        symbol = '¥';
        break;
      default:
        symbol = '$currency ';
    }
    final isNegative = amount < 0;
    final absAmount = amount.abs();

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
        buffer.write(',');
      }
    }

    final formattedInt = buffer.toString().split('').reversed.join('');
    final formattedValue = '$symbol$formattedInt.$decimalPart';
    return isNegative ? '-$formattedValue' : formattedValue;
  }

  /// Formats a 12-hour time string (e.g. "2:30 PM", "11:15 AM")
  static String formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Day of week (e.g. "Monday", "Saturday")
  static String formatDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Formats a DateTime with day, date and exact time (e.g. "Today • 2:30 PM", "13 Sep • 11:15 AM")
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final timeStr = formatTime(date);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return 'Today • $timeStr';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year && yesterday.month == date.month && yesterday.day == date.day) {
      return 'Yesterday • $timeStr';
    }

    if (now.year == date.year) {
      return '${date.day} ${months[date.month - 1]} • $timeStr';
    }

    return '${date.day} ${months[date.month - 1]} ${date.year} • $timeStr';
  }

  /// Full verbose date and time (e.g. "Saturday, 13 Sep 2026 at 11:15 AM")
  static String formatFullDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = formatDayOfWeek(date);
    final timeStr = formatTime(date);
    return '$dayName, ${date.day} ${months[date.month - 1]} ${date.year} at $timeStr';
  }

  /// Formats a percentage change (e.g. "+12.5%", "-3.2%")
  static String formatPercentage(double percent) {
    final prefix = percent > 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(1)}%';
  }
}
