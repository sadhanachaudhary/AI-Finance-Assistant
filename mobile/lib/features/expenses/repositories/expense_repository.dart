import 'package:dio/dio.dart';
import '../../../networking/api_client.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository(this._apiClient);

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _apiClient.dio.get('/expenses');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final list = response.data['data']['expenses'] as List;
        return list.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load expenses';
    }
  }

  Future<Expense> createExpense({
    required double amount,
    String currency = 'INR',
    required DateTime date,
    String? merchant,
    String? notes,
    String? categoryId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/expenses',
        data: {
          'amount': amount,
          'currency': currency,
          'date': date.toIso8601String(),
          if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        },
      );

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        return Expense.fromJson(response.data['data']['expense'] as Map<String, dynamic>);
      }
      throw 'Failed to create expense';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create expense';
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.dio.delete('/expenses/$id');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete expense';
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final list = response.data['data']['categories'] as List;
        return list.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load categories';
    }
  }

  Future<Category> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/categories',
        data: {
          'name': name,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
        },
      );

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        return Category.fromJson(response.data['data']['category'] as Map<String, dynamic>);
      }
      throw 'Failed to create category';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create category';
    }
  }
}
