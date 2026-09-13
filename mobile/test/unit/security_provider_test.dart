import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/shared/providers/security_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  group('SecurityProvider & Zero-Trust Architecture Tests', () {
    test('Initial state provides 100% Institutional Fortress (Level 4)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read initial state
      final state = container.read(securityProvider);
      expect(state.securityScore, 100);
      expect(state.isRestricted, false);
      expect(state.tier, SecurityTier.fortress);
      expect(state.tierName, 'Institutional Fortress (Level 4)');
    });

    test('Disabling Layer 1 OTP Shield triggers Restricted Mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(securityProvider.notifier).toggleOtpShield(false);

      final state = container.read(securityProvider);
      expect(state.otpShield, false);
      expect(state.isRestricted, true);
      expect(state.tier, SecurityTier.restricted);
      expect(state.tierName, 'RESTRICTED (Security Alert)');
    });

    test('Disabling Layer 2 PII Redaction triggers Restricted Mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(securityProvider.notifier).togglePiiShield(false);

      final state = container.read(securityProvider);
      expect(state.piiShield, false);
      expect(state.isRestricted, true);
      expect(state.tier, SecurityTier.restricted);
    });

    test('Disabling optional Layer 3/4 decreases score to Guarded without restriction', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(securityProvider.notifier);
      await notifier.toggleAutoLock(false);
      await notifier.toggleMaskAccounts(false);

      final state = container.read(securityProvider);
      expect(state.isRestricted, false);
      expect(state.securityScore, 75);
      expect(state.tier, SecurityTier.guarded);
    });

    test('restoreAllProtections() restores 100% score and clears restriction', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(securityProvider.notifier);
      await notifier.toggleOtpShield(false);
      expect(container.read(securityProvider).isRestricted, true);

      await notifier.restoreAllProtections();
      final restored = container.read(securityProvider);
      expect(restored.isRestricted, false);
      expect(restored.securityScore, 100);
      expect(restored.tier, SecurityTier.fortress);
    });
  });
}
