import 'package:flutter/material.dart';
import '../../../shared/widgets/app_card.dart';

class PrivacySecuritySheet extends StatefulWidget {
  const PrivacySecuritySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacySecuritySheet(),
    );
  }

  @override
  State<PrivacySecuritySheet> createState() => _PrivacySecuritySheetState();
}

class _PrivacySecuritySheetState extends State<PrivacySecuritySheet> {
  bool _onDeviceOnly = true;
  bool _maskAccounts = true;
  bool _autoRejectOtp = true;
  bool _aiCategorization = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2C2C3E), width: 1.5)),
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
                    color: const Color(0xFF03DAC6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF03DAC6), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy & Security Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Zero-Trust Financial Architecture',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Security Highlights Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              gradientColors: const [Color(0xFF1E2838), Color(0xFF121620)],
              child: Column(
                children: [
                  _buildSecurityRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Read-Only Spending Metadata',
                    subtitle: 'We only store amount, merchant name & date. No funds can ever be moved.',
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSecurityRow(
                    icon: Icons.phonelink_lock_rounded,
                    title: 'On-Device Parsing',
                    subtitle: 'Transaction SMS and notifications are processed locally inside your phone.',
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildSecurityRow(
                    icon: Icons.vpn_key_off_rounded,
                    title: 'Zero Credential Storage',
                    subtitle: 'Never asked for bank passwords, UPI PINs, CVVs, or OTPs.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Privacy Controls & Toggles',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            _buildToggleTile(
              title: 'On-Device SMS Parsing Only',
              subtitle: 'Never transmit raw notification strings to cloud servers',
              value: _onDeviceOnly,
              onChanged: (val) => setState(() => _onDeviceOnly = val),
            ),
            _buildToggleTile(
              title: 'Mask Bank Account Numbers',
              subtitle: 'Keep all account numbers masked as XX1234',
              value: _maskAccounts,
              onChanged: (val) => setState(() => _maskAccounts = val),
            ),
            _buildToggleTile(
              title: 'Strict OTP & Security Code Shield',
              subtitle: 'Instantly block and discard any SMS containing OTP or auth codes',
              value: _autoRejectOtp,
              onChanged: (val) => setState(() => _autoRejectOtp = val),
            ),
            _buildToggleTile(
              title: 'Smart AI Auto-Categorization',
              subtitle: 'Automatically assign categories based on merchant names',
              value: _aiCategorization,
              onChanged: (val) => setState(() => _aiCategorization = val),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF03DAC6), size: 20),
        const SizedBox(width: 12),
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
                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C3E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF6C63FF),
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
