import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoalRepository(apiClient);
});

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<GoalModel>>(() => GoalsNotifier());

class GoalsNotifier extends AsyncNotifier<List<GoalModel>> {
  late GoalRepository _repo;

  @override
  Future<List<GoalModel>> build() async {
    _repo = ref.watch(goalRepositoryProvider);
    final goals = await _repo.getGoals();

    // If server has no goals yet (or during demo mode), provide smart starter presets
    if (goals.isEmpty) {
      return [
        GoalModel(
          id: 'demo-emergency',
          name: 'Emergency Fund',
          targetAmount: 50000,
          currentAmount: 18500,
          currency: 'INR',
          deadline: DateTime.now().add(const Duration(days: 90)),
          category: 'Safety',
          color: '0xFF10B981',
          icon: 'emergency',
          createdAt: DateTime.now(),
        ),
        GoalModel(
          id: 'demo-vacation',
          name: 'Goa Summer Trip',
          targetAmount: 25000,
          currentAmount: 12000,
          currency: 'INR',
          deadline: DateTime.now().add(const Duration(days: 60)),
          category: 'Travel',
          color: '0xFF3B82F6',
          icon: 'travel',
          createdAt: DateTime.now(),
        ),
        GoalModel(
          id: 'demo-tech',
          name: 'M3 MacBook Air',
          targetAmount: 95000,
          currentAmount: 42000,
          currency: 'INR',
          deadline: DateTime.now().add(const Duration(days: 150)),
          category: 'Gadgets',
          color: '0xFF8B5CF6',
          icon: 'laptop',
          createdAt: DateTime.now(),
        ),
      ];
    }
    return goals;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getGoals());
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0.0,
    String currency = 'INR',
    DateTime? deadline,
    String? category,
    String? color,
    String? icon,
  }) async {
    try {
      final created = await _repo.createGoal(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        currency: currency,
        deadline: deadline,
        category: category,
        color: color,
        icon: icon,
      );

      final newGoal = created ??
          GoalModel(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            currency: currency,
            deadline: deadline,
            category: category,
            color: color,
            icon: icon,
            createdAt: DateTime.now(),
          );

      state = AsyncValue.data([newGoal, ...state.value ?? []]);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deposit(String id, double amount) async {
    try {
      await _repo.depositToGoal(id, amount);
      final currentList = state.value ?? [];
      final updatedList = currentList.map((g) {
        if (g.id == id) {
          return GoalModel(
            id: g.id,
            name: g.name,
            targetAmount: g.targetAmount,
            currentAmount: g.currentAmount + amount,
            currency: g.currency,
            deadline: g.deadline,
            category: g.category,
            color: g.color,
            icon: g.icon,
            createdAt: g.createdAt,
          );
        }
        return g;
      }).toList();

      state = AsyncValue.data(updatedList);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((g) => g.id != id).toList());
  }
}

// Derived overall savings stats
final totalSavingsTargetProvider = Provider<double>((ref) {
  final goals = ref.watch(goalsProvider).value ?? [];
  return goals.reduce((sum, g) => GoalModel(
    id: '',
    name: '',
    targetAmount: sum.targetAmount + g.targetAmount,
    currentAmount: 0,
    createdAt: DateTime.now(),
  )).targetAmount;
});

final totalSavedAmountProvider = Provider<double>((ref) {
  final goals = ref.watch(goalsProvider).value ?? [];
  return goals.fold(0.0, (sum, g) => sum + g.currentAmount);
});
