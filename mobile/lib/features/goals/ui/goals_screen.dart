import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import 'add_goal_sheet.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  void _showDepositDialog(GoalModel goal) {
    final controller = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goal.parsedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(goal.parsedIcon, color: goal.parsedColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add to "${goal.name}"',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter deposit amount to contribute to this goal:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: AppTheme.tabularNumbers(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (₹)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.inflowGreen),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final depositVal = double.tryParse(controller.text.trim());
                if (depositVal != null && depositVal > 0) {
                  ref.read(goalsProvider.notifier).deposit(goal.id, depositVal);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryPurple,
                      content: Text('🎉 Added ${Formatters.formatCurrency(depositVal)} to "${goal.name}"!'),
                    ),
                  );
                }
              },
              child: const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGoal(GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Savings Goal?', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to remove "${goal.name}"? Your saved balance record will be removed.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.outflowCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(goalsProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final totalTarget = ref.watch(totalSavingsTargetProvider);
    final totalSaved = ref.watch(totalSavedAmountProvider);
    final overallPercentage = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryPurple, size: 26),
            onPressed: () => AddGoalSheet.show(context),
          ),
        ],
      ),
      body: goalsState.when(
        loading: () => const AppLoading(message: 'Loading savings goals...'),
        error: (err, _) => AppErrorView(
          message: err.toString(),
          onRetry: () => ref.read(goalsProvider.notifier).refresh(),
        ),
        data: (goals) {
          return RefreshIndicator(
            onRefresh: () async => ref.read(goalsProvider.notifier).refresh(),
            color: AppTheme.primaryPurple,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Overall Savings Summary
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Savings Progress',
                              style: AppTypography.bodySmall.copyWith(color: AppTheme.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.softPurpleBadge,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${(overallPercentage * 100).toStringAsFixed(0)}% Overall',
                                style: AppTheme.tabularNumbers(
                                  color: AppTheme.primaryPurple,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Formatters.formatCurrency(totalSaved),
                          style: AppTheme.tabularNumbers(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'of ${Formatters.formatCurrency(totalTarget)} total target',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallPercentage,
                            minHeight: 8,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header with Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Targets (${goals.length})',
                        style: AppTypography.h2,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryPurple),
                        label: const Text('New Goal', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        onPressed: () => AddGoalSheet.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (goals.isEmpty)
                    AppEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'No savings goals yet',
                      subtitle: 'Set a target for an emergency fund, vacation, or gadget to build consistent wealth.',
                      actionText: 'Create First Goal',
                      onAction: () => AddGoalSheet.show(context),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: goals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final isFinished = goal.isCompleted;

                        return AppCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: goal.parsedColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(goal.parsedIcon, color: goal.parsedColor, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                goal.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isFinished)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.softGreenBadge,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  '🏆 Reached',
                                                  style: TextStyle(color: AppTheme.inflowGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (goal.category != null) ...[
                                              Text(
                                                goal.category!,
                                                style: TextStyle(color: goal.parsedColor, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                              const Text(' • ', style: TextStyle(color: AppTheme.textTertiary)),
                                            ],
                                            if (goal.daysRemaining != null)
                                              Text(
                                                '${goal.daysRemaining} days left',
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              )
                                            else
                                              const Text('Ongoing goal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textTertiary, size: 20),
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    onSelected: (val) {
                                      if (val == 'deposit') _showDepositDialog(goal);
                                      if (val == 'delete') _confirmDeleteGoal(goal);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'deposit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle_outline, color: AppTheme.primaryPurple, size: 18),
                                            SizedBox(width: 8),
                                            Text('Add Deposit', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: AppTheme.outflowCoral, size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete Goal', style: TextStyle(color: AppTheme.outflowCoral, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Amount Details Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(goal.currentAmount, currency: goal.currency),
                                    style: AppTheme.tabularNumbers(
                                      color: AppTheme.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Target: ${Formatters.formatCurrency(goal.targetAmount, currency: goal.currency)}',
                                    style: AppTheme.tabularNumbers(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: goal.percentage,
                                  minHeight: 7,
                                  backgroundColor: AppTheme.surfaceElevated,
                                  valueColor: AlwaysStoppedAnimation<Color>(goal.parsedColor),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Footer Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(goal.percentage * 100).toStringAsFixed(0)}% Saved (${Formatters.formatCurrency(goal.remainingAmount, currency: goal.currency)} to go)',
                                    style: AppTheme.tabularNumbers(color: AppTheme.textSecondary, fontSize: 11.5),
                                  ),
                                  InkWell(
                                    onTap: () => _showDepositDialog(goal),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: goal.parsedColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, size: 14, color: goal.parsedColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Deposit',
                                            style: TextStyle(
                                              color: goal.parsedColor,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
