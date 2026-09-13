import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage secureStorage = SecureStorage();

  ApiClient() {
    // 10.0.2.2 is the special IP for Android emulators to connect to localhost.
    // For iOS simulator, web, or desktop, localhost works.
    String baseUrl = const String.fromEnvironment('API_URL', defaultValue: '');
    
    if (baseUrl.isEmpty) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:3001/api';
      } else {
        baseUrl = 'http://localhost:3001/api';
      }
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}
