import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../networking/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data['data'];
      return {
        'user': User.fromJson(data['user']),
        'token': data['token'] as String,
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.register, data: {
        'email': email,
        'password': password,
        'name': name,
      });
      
      final data = response.data['data'];
      // Note: Backend register doesn't return a token right now, so we just return the user.
      return {
        'user': User.fromJson(data['user']),
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }
}
