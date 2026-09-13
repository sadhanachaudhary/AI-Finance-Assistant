import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../storage/secure_storage.dart';

class CurrencyConfig {
  final String code;
  final String symbol;
  final String name;

  const CurrencyConfig({required this.code, required this.symbol, required this.name});
}

const List<CurrencyConfig> supportedCurrencies = [
  CurrencyConfig(code: 'INR', symbol: '₹', name: 'Indian Rupee (INR)'),
  CurrencyConfig(code: 'USD', symbol: r'$', name: 'US Dollar (USD)'),
  CurrencyConfig(code: 'EUR', symbol: '€', name: 'Euro (EUR)'),
  CurrencyConfig(code: 'GBP', symbol: '£', name: 'British Pound (GBP)'),
  CurrencyConfig(code: 'AED', symbol: 'AED ', name: 'UAE Dirham (AED)'),
  CurrencyConfig(code: 'CAD', symbol: r'CA$', name: 'Canadian Dollar (CAD)'),
];

final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyConfig>(() => CurrencyNotifier());

class CurrencyNotifier extends Notifier<CurrencyConfig> {
  late SecureStorage _storage;

  @override
  CurrencyConfig build() {
    _storage = ref.watch(secureStorageProvider);
    _loadSavedCurrency();
    return supportedCurrencies[0];
  }

  Future<void> _loadSavedCurrency() async {
    try {
      final code = await _storage.read('preferred_currency');
      if (code != null) {
        final found = supportedCurrencies.firstWhere((c) => c.code == code, orElse: () => supportedCurrencies[0]);
        state = found;
      }
    } catch (_) {}
  }

  Future<void> setCurrency(CurrencyConfig config) async {
    state = config;
    try {
      await _storage.write('preferred_currency', config.code);
    } catch (_) {}
  }
}
