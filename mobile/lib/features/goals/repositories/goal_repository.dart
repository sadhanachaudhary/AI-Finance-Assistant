import '../../../core/constants/api_endpoints.dart';
import '../../../networking/api_client.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final ApiClient _apiClient;

  GoalRepository(this._apiClient);

  Future<List<GoalModel>> getGoals() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.goals);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data.map((json) => GoalModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<GoalModel?> createGoal({
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
      final response = await _apiClient.dio.post(
        ApiEndpoints.goals,
        data: {
          'name': name,
          'targetAmount': targetAmount,
          'currentAmount': currentAmount,
          'currency': currency,
          'deadline': deadline?.toIso8601String(),
          'category': category,
          'color': color,
          'icon': icon,
        },
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        return GoalModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<GoalModel?> depositToGoal(String id, double amount) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.goalDeposit(id),
        data: {'amount': amount},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return GoalModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      final response = await _apiClient.dio.delete(ApiEndpoints.goalById(id));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
