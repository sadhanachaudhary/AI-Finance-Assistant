import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import 'export_statement_sheet.dart';
import 'privacy_security_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).value;
    final userName = authUser?.name ?? authUser?.email.split('@').first ?? 'User';
    final userEmail = authUser?.email ?? 'user@example.com';
    final expenses = ref.watch(expensesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Avatar Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              gradientColors: const [Color(0xFF26224A), Color(0xFF161528)],
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03DAC6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${expenses.length} Records Logged',
                            style: const TextStyle(color: Color(0xFF03DAC6), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Reports Section
            _buildSectionHeader('Data & Exports'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Spending Statement (CSV)',
                    trailing: 'Download',
                    onTap: () => ExportStatementSheet.show(context),
                  ),
                  const Divider(height: 1, color: Color(0xFF2C2C2C)),
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Zero-Trust Security',
                    trailing: 'Manage',
                    onTap: () => PrivacySecuritySheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Group
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Default Currency',
                    trailing: 'INR (₹)',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xFF2C2C2C)),
                  _buildListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Smart Ingest Notifications',
                    trailing: 'Active',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            AppButton(
              text: 'Log Out',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.outlined,
              backgroundColor: const Color(0xFFCF6679),
              textColor: const Color(0xFFCF6679),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Finance Assistant • v1.2.0 (Fintech Edition)',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
