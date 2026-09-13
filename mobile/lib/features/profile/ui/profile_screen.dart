import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/currency_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import 'export_statement_sheet.dart';
import 'privacy_security_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(currencyProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppTheme.bgSlate,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.borderSlate, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Select Preferred Currency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...supportedCurrencies.map((c) {
              final isSelected = c.code == current.code;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.trustBlue.withValues(alpha: 0.15) : AppTheme.surfaceSlate,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.trustBlue : AppTheme.borderSlate,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Text(
                    c.symbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.trustBlue : Colors.white,
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.trustBlue)
                      : null,
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(c);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).value;
    final currency = ref.watch(currencyProvider);
    final userName = authUser?.name ?? authUser?.email.split('@').first ?? 'User';
    final userEmail = authUser?.email ?? 'user@example.com';
    final expenses = ref.watch(expensesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Avatar Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              gradientColors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.trustBlue, AppTheme.trustTeal],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inflowGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${expenses.length} Records Logged',
                            style: const TextStyle(
                              color: AppTheme.inflowGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Financial Modules Shortcut Section
            _buildSectionHeader('Financial Tools & Targets'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.flag_rounded,
                    title: 'Savings Goals & Sinking Funds',
                    trailing: 'View Goals',
                    iconColor: AppTheme.inflowGreen,
                    onTap: () => context.go('/goals'),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSlate),
                  _buildListTile(
                    icon: Icons.insights_rounded,
                    title: 'Budget Health & Burn Rate Forecast',
                    trailing: 'Analytics',
                    iconColor: AppTheme.trustBlue,
                    onTap: () => context.go('/analytics'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Reports Section
            _buildSectionHeader('Data & Zero-Trust Security'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Spending Statement (CSV)',
                    trailing: 'Download',
                    iconColor: AppTheme.trustTeal,
                    onTap: () => ExportStatementSheet.show(context),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSlate),
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Zero-Trust Security Shield',
                    trailing: 'Active',
                    iconColor: AppTheme.inflowGreen,
                    onTap: () => PrivacySecuritySheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Group
            _buildSectionHeader('App Preferences'),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Default Currency',
                    trailing: '${currency.code} (${currency.symbol})',
                    iconColor: AppTheme.warningAmber,
                    onTap: () => _showCurrencyPicker(context, ref),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSlate),
                  _buildListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Smart Spending Alerts',
                    trailing: 'Enabled',
                    iconColor: AppTheme.trustBlue,
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
              backgroundColor: AppTheme.outflowCoral,
              textColor: AppTheme.outflowCoral,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Finance Assistant • v1.3.0 (Fintech Edition)',
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
          fontSize: 13.5,
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
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final effectiveColor = iconColor ?? AppTheme.trustBlue;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: effectiveColor, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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

