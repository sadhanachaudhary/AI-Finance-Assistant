import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'dart:io';

class ApiClient {
  late final Dio dio;
  final SecureStorage secureStorage = SecureStorage();

  ApiClient() {
    // 10.0.2.2 is the special IP for Android emulators to connect to localhost.
    // For iOS simulator or web, localhost works fine. We will use a simple check.
    String baseUrl = const String.fromEnvironment('API_URL', defaultValue: '');
    
    if (baseUrl.isEmpty) {
      if (Platform.isAndroid) {
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
