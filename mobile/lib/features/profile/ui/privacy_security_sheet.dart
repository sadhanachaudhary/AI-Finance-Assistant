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
        backgroundColor: AppTheme.textPrimary,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.outflowCoral, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Security Restriction Alert',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Disabling "$featureName" will compromise your financial privacy baseline and switch the app into RESTRICTED MODE.\n\nAI queries, cloud sync, and smart ingestion will be disabled until restored.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Protected', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.outflowCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
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
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy & Security Shield',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sec.isRestricted ? 'Restricted Security Mode' : 'Zero-Trust Architecture Active',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: sec.isRestricted ? AppTheme.outflowCoral : AppTheme.inflowGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Layer 1: OTP Shield
            _buildSecurityTile(
              title: 'Layer 1: Auto-Discard Bank OTPs',
              description: 'Automatically intercepts and scrubs OTP verification messages.',
              icon: Icons.shield_rounded,
              color: AppTheme.primaryPurple,
              isActive: sec.otpShield,
              onChanged: (val) {
                if (!val) {
                  _confirmMandatoryDisable(context, 'Auto-Discard OTPs', () {
                    notifier.toggleOtpShield(false);
                    _showFeedback(context, 'OTP Shield disabled. App is now in Restricted Mode.', isWarning: true);
                  });
                } else {
                  notifier.toggleOtpShield(true);
                  _showFeedback(context, 'OTP Shield restored.');
                }
              },
            ),

            const SizedBox(height: 12),

            // Layer 2: PII Redaction
            _buildSecurityTile(
              title: 'Layer 2: Real-time PII Scrubbing',
              description: 'Auto-redacts bank card numbers, CVVs, passwords & accounts before processing.',
              icon: Icons.vpn_key_rounded,
              color: AppTheme.trustTeal,
              isActive: sec.piiShield,
              onChanged: (val) {
                if (!val) {
                  _confirmMandatoryDisable(context, 'Real-time PII Scrubbing', () {
                    notifier.togglePiiShield(false);
                    _showFeedback(context, 'PII Redaction disabled. App in Restricted Mode.', isWarning: true);
                  });
                } else {
                  notifier.togglePiiShield(true);
                  _showFeedback(context, 'PII Redaction restored.');
                }
              },
            ),

            const SizedBox(height: 12),

            // Layer 3: Biometric Lock
            _buildSecurityTile(
              title: 'Layer 3: Biometric Lock',
              description: 'Require FaceID / Fingerprint on app resume.',
              icon: Icons.fingerprint_rounded,
              color: AppTheme.inflowGreen,
              isActive: sec.biometricLock,
              onChanged: (val) {
                notifier.toggleBiometricLock(val);
                _showFeedback(context, val ? 'Biometric security activated.' : 'Biometrics disabled.');
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isActive,
            activeColor: AppTheme.primaryPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
