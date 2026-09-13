import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/security_provider.dart';

class PrivacySecuritySheet extends ConsumerWidget {
  const PrivacySecuritySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacySecuritySheet(),
    );
  }

  void _showFeedback(BuildContext context, String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isWarning ? AppTheme.outflowCoral : Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _confirmMandatoryDisable(BuildContext context, String featureName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.outflowCoral, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Security Restriction Alert',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Disabling "$featureName" will compromise your financial privacy baseline and switch the app into RESTRICTED MODE.\n\nAI queries, cloud sync, and smart ingestion will be disabled until restored.',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Protected', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.outflowCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Restrict App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sec = ref.watch(securityProvider);
    final notifier = ref.read(securityProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: sec.isRestricted
                          ? [AppTheme.outflowCoral, const Color(0xFFE11D48)]
                          : [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sec.isRestricted ? Icons.lock_person_rounded : Icons.shield_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Multi-Layer Security Center',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        sec.tierName,
                        style: TextStyle(
                          fontSize: 12,
                          color: sec.isRestricted ? AppTheme.outflowCoral : const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Posture Score Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: sec.isRestricted ? AppTheme.outflowCoral.withValues(alpha: 0.5) : const Color(0xFF334155),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Security Posture Score',
                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${sec.securityScore}%',
                        style: TextStyle(
                          color: sec.isRestricted ? AppTheme.outflowCoral : AppTheme.inflowGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: sec.securityScore / 100.0,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        sec.isRestricted ? AppTheme.outflowCoral : AppTheme.inflowGreen,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (sec.isRestricted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.outflowCoral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.outflowCoral.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: AppTheme.outflowCoral, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'App restricted due to missing baseline security layers.',
                              style: TextStyle(color: AppTheme.outflowCoral, fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              notifier.restoreAllProtections();
                              _showFeedback(context, '🛡️ All 4 Security Layers Restored (100% Fortress)');
                            },
                            child: const Text('Fix All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LAYER 1: Mandatory Core Protection
            _buildLayerHeader(
              layerNumber: 'LAYER 1',
              title: 'Core Device Integrity',
              badge: 'MANDATORY',
              badgeColor: AppTheme.trustBlue,
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Strict OTP & Security Code Shield',
              subtitle: 'Instantly block and discard any SMS containing OTP or auth codes',
              value: sec.otpShield,
              onChanged: (val) {
                if (!val) {
                  _confirmMandatoryDisable(context, 'Strict OTP Shield', () => notifier.toggleOtpShield(false));
                } else {
                  notifier.toggleOtpShield(true);
                  _showFeedback(context, '🔒 OTP Shield Activated');
                }
              },
            ),
            _buildToggleTile(
              title: 'On-Device SMS Parsing Only',
              subtitle: 'Never transmit raw bank notification strings to cloud servers',
              value: sec.onDeviceOnly,
              onChanged: (val) {
                if (!val) {
                  _confirmMandatoryDisable(context, 'On-Device SMS Parsing', () => notifier.toggleOnDeviceOnly(false));
                } else {
                  notifier.toggleOnDeviceOnly(true);
                  _showFeedback(context, '📱 On-Device Ingestion Active');
                }
              },
            ),
            const SizedBox(height: 16),

            // LAYER 2: AI Zero-Trust & PII Sanitizer
            _buildLayerHeader(
              layerNumber: 'LAYER 2',
              title: 'AI Zero-Trust & PII Shield',
              badge: 'PRIVACY LEVEL',
              badgeColor: AppTheme.trustTeal,
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Automated PII & Credential Redactor',
              subtitle: 'Scrub cards, CVVs, PINs & account numbers before AI processing',
              value: sec.piiShield,
              onChanged: (val) {
                if (!val) {
                  _confirmMandatoryDisable(context, 'PII Redactor Shield', () => notifier.togglePiiShield(false));
                } else {
                  notifier.togglePiiShield(true);
                  _showFeedback(context, '🛡️ PII Redaction Shield Active');
                }
              },
            ),
            _buildToggleTile(
              title: 'Mask Bank Account Numbers',
              subtitle: 'Keep all account numbers masked as XX1234',
              value: sec.maskAccounts,
              onChanged: (val) {
                notifier.toggleMaskAccounts(val);
                _showFeedback(context, val ? '🔒 Account Masking Active' : 'Account Masking Disabled');
              },
            ),
            const SizedBox(height: 16),

            // LAYER 3: Access & Hardware Guard
            _buildLayerHeader(
              layerNumber: 'LAYER 3',
              title: 'Biometric & Access Guard',
              badge: 'DEVICE LEVEL',
              badgeColor: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Hardware Biometric Guard',
              subtitle: 'Require FaceID / Fingerprint / Device PIN to unlock ledger',
              value: sec.biometricLock,
              onChanged: (val) {
                notifier.toggleBiometricLock(val);
                _showFeedback(context, val ? '🔒 Biometric Lock Enabled' : 'Biometric Lock Disabled');
              },
            ),
            _buildToggleTile(
              title: 'Auto-Lock on App Background',
              subtitle: 'Immediately require auth when switching between apps',
              value: sec.autoLock,
              onChanged: (val) {
                notifier.toggleAutoLock(val);
                _showFeedback(context, val ? '⏱️ Background Auto-Lock Active' : 'Auto-Lock Disabled');
              },
            ),
            const SizedBox(height: 16),

            // LAYER 4: Export Armor
            _buildLayerHeader(
              layerNumber: 'LAYER 4',
              title: 'Data Fortress & Export Armor',
              badge: 'STORAGE LEVEL',
              badgeColor: AppTheme.inflowGreen,
            ),
            const SizedBox(height: 8),
            _buildToggleTile(
              title: 'Statement Passphrase Encryption',
              subtitle: 'Require user passphrase for all exported CSV & PDF financial records',
              value: sec.exportEncryption,
              onChanged: (val) {
                notifier.toggleExportEncryption(val);
                _showFeedback(context, val ? '🔐 Export Encryption Active' : 'Export Encryption Disabled');
              },
            ),
            const SizedBox(height: 24),

            // Restore defaults action
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                notifier.restoreAllProtections();
                _showFeedback(context, '🛡️ Restored All 4 Security Layers (100% Fortress)');
              },
              icon: const Icon(Icons.verified_user_rounded, color: AppTheme.inflowGreen, size: 20),
              label: const Text(
                'Enforce Full Institutional Protection (100%)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerHeader({
    required String layerNumber,
    required String title,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Text(
          layerNumber,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF2563EB),
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
