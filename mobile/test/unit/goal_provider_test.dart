import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/goals/models/goal_model.dart';
import 'package:mobile/features/goals/providers/goal_provider.dart';

void main() {
  group('Goal Provider Derived Stats Tests', () {
    test('totalSavingsTargetProvider and totalSavedAmountProvider handle empty list safely', () {
      final container = ProviderContainer(
        overrides: [
          goalsProvider.overrideWith(() => EmptyMockGoalsNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final target = container.read(totalSavingsTargetProvider);
      final saved = container.read(totalSavedAmountProvider);

      expect(target, 0.0);
      expect(saved, 0.0);
    });
  });
}

class EmptyMockGoalsNotifier extends GoalsNotifier {
  @override
  Future<List<GoalModel>> build() async => [];
}
