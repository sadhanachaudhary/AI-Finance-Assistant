import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/secure_storage.dart';

enum SecurityTier {
  fortress, // 100% all layers active
  guarded,  // Good protection
  warning,  // Missing privacy layers
  restricted // Critical baseline missing - Restricted App Mode
}

class SecurityState {
  final bool otpShield;          // Layer 1: Mandatory OTP Discard
  final bool onDeviceOnly;       // Layer 1: Mandatory On-device SMS parsing
  final bool piiShield;          // Layer 2: PII & Card Scrubbing
  final bool maskAccounts;       // Layer 2: Account Number Masking
  final bool biometricLock;      // Layer 3: Hardware Biometric Guard
  final bool autoLock;           // Layer 3: Auto-Lock on Background
  final bool exportEncryption;   // Layer 4: Export Passphrase Armor

  const SecurityState({
    this.otpShield = true,
    this.onDeviceOnly = true,
    this.piiShield = true,
    this.maskAccounts = true,
    this.biometricLock = true,
    this.autoLock = true,
    this.exportEncryption = true,
  });

  bool get isRestricted => !otpShield || !piiShield || !onDeviceOnly;

  int get securityScore {
    int score = 0;
    if (otpShield) score += 20;
    if (onDeviceOnly) score += 20;
    if (piiShield) score += 20;
    if (maskAccounts) score += 15;
    if (biometricLock) score += 10;
    if (autoLock) score += 10;
    if (exportEncryption) score += 5;
    return score;
  }

  SecurityTier get tier {
    if (isRestricted) return SecurityTier.restricted;
    final s = securityScore;
    if (s >= 90) return SecurityTier.fortress;
    if (s >= 70) return SecurityTier.guarded;
    return SecurityTier.warning;
  }

  String get tierName {
    switch (tier) {
      case SecurityTier.fortress:
        return 'Institutional Fortress (Level 4)';
      case SecurityTier.guarded:
        return 'Standard Protection (Level 3)';
      case SecurityTier.warning:
        return 'Reduced Security (Level 2)';
      case SecurityTier.restricted:
        return 'RESTRICTED (Security Alert)';
    }
  }

  SecurityState copyWith({
    bool? otpShield,
    bool? onDeviceOnly,
    bool? piiShield,
    bool? maskAccounts,
    bool? biometricLock,
    bool? autoLock,
    bool? exportEncryption,
  }) {
    return SecurityState(
      otpShield: otpShield ?? this.otpShield,
      onDeviceOnly: onDeviceOnly ?? this.onDeviceOnly,
      piiShield: piiShield ?? this.piiShield,
      maskAccounts: maskAccounts ?? this.maskAccounts,
      biometricLock: biometricLock ?? this.biometricLock,
      autoLock: autoLock ?? this.autoLock,
      exportEncryption: exportEncryption ?? this.exportEncryption,
    );
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(SecurityNotifier.new);

class SecurityNotifier extends Notifier<SecurityState> {
  final SecureStorage _storage = SecureStorage();

  @override
  SecurityState build() {
    _loadFromStorage();
    return const SecurityState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final otp = await _storage.read('sec_otp');
      final dev = await _storage.read('sec_dev');
      final pii = await _storage.read('sec_pii');
      final mask = await _storage.read('sec_mask');
      final bio = await _storage.read('sec_bio');
      final auto = await _storage.read('sec_auto');
      final exp = await _storage.read('sec_exp');

      if (!ref.mounted) return;

      state = SecurityState(
        otpShield: otp == null || otp == 'true',
        onDeviceOnly: dev == null || dev == 'true',
        piiShield: pii == null || pii == 'true',
        maskAccounts: mask == null || mask == 'true',
        biometricLock: bio == null || bio == 'true',
        autoLock: auto == null || auto == 'true',
        exportEncryption: exp == null || exp == 'true',
      );
    } catch (_) {
      // Safe fallback for uninitialized storage or disposed refs
    }
  }

  Future<void> toggleOtpShield(bool val) async {
    state = state.copyWith(otpShield: val);
    await _storage.write('sec_otp', val.toString());
  }

  Future<void> toggleOnDeviceOnly(bool val) async {
    state = state.copyWith(onDeviceOnly: val);
    await _storage.write('sec_dev', val.toString());
  }

  Future<void> togglePiiShield(bool val) async {
    state = state.copyWith(piiShield: val);
    await _storage.write('sec_pii', val.toString());
  }

  Future<void> toggleMaskAccounts(bool val) async {
    state = state.copyWith(maskAccounts: val);
    await _storage.write('sec_mask', val.toString());
  }

  Future<void> toggleBiometricLock(bool val) async {
    state = state.copyWith(biometricLock: val);
    await _storage.write('sec_bio', val.toString());
  }

  Future<void> toggleAutoLock(bool val) async {
    state = state.copyWith(autoLock: val);
    await _storage.write('sec_auto', val.toString());
  }

  Future<void> toggleExportEncryption(bool val) async {
    state = state.copyWith(exportEncryption: val);
    await _storage.write('sec_exp', val.toString());
  }

  Future<void> restoreAllProtections() async {
    state = const SecurityState();
    await _storage.write('sec_otp', 'true');
    await _storage.write('sec_dev', 'true');
    await _storage.write('sec_pii', 'true');
    await _storage.write('sec_mask', 'true');
    await _storage.write('sec_bio', 'true');
    await _storage.write('sec_auto', 'true');
    await _storage.write('sec_exp', 'true');
  }
}
