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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                const Expanded(
                  child: Text(
                    'Select Preferred Currency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...supportedCurrencies.map((c) {
              final isSelected = c.code == current.code;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.softPurpleBadge : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryPurple : AppTheme.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Text(
                    c.symbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryPurple)
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
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Avatar Card
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.softPurpleBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '💎 Smart Premium Plan',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings & Preferences
            const SectionHeader(title: 'Preferences & Features'),
            const SizedBox(height: 8),

            ActionCardTile(
              icon: Icons.currency_exchange_rounded,
              iconColor: AppTheme.primaryPurple,
              title: 'Default Currency',
              subtitle: '${currency.name} (${currency.symbol})',
              onTap: () => _showCurrencyPicker(context, ref),
              margin: const EdgeInsets.only(bottom: 10),
            ),

            ActionCardTile(
              icon: Icons.security_rounded,
              iconColor: AppTheme.inflowGreen,
              title: 'Privacy & Security Shield',
              subtitle: 'Zero-Trust data redaction and local safeguards',
              onTap: () => PrivacySecuritySheet.show(context),
              margin: const EdgeInsets.only(bottom: 10),
            ),

            ActionCardTile(
              icon: Icons.file_download_outlined,
              iconColor: AppTheme.primaryPurple,
              title: 'Export Financial Statements',
              subtitle: 'Download monthly CSV/Excel statement',
              onTap: () => ExportStatementSheet.show(context, expenses),
              margin: const EdgeInsets.only(bottom: 10),
            ),

            const SizedBox(height: 24),

            // Account & Logout
            const SectionHeader(title: 'Account'),
            const SizedBox(height: 8),

            ActionCardTile(
              icon: Icons.logout_rounded,
              iconColor: AppTheme.outflowCoral,
              title: 'Log Out',
              subtitle: 'Securely sign out of this device',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Confirm Logout', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.outflowCoral),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
