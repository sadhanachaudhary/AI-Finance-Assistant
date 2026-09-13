import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/utils/error_mapper.dart';

void main() {
  group('ErrorMapper Unit Tests', () {
    test('Maps connection timeout to friendly timeout guidance', () {
      final dioErr = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/expenses'),
      );

      final result = ErrorMapper.map(dioErr);
      expect(result.title, 'Connection Timed Out');
      expect(result.isNetworkIssue, true);
      expect(result.tip, contains('check your internet connection'));
    });

    test('Maps 401 Unauthorized to Session Expired', () {
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/expenses'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/expenses'),
          data: {'message': 'jwt expired'},
        ),
      );

      final result = ErrorMapper.map(dioErr);
      expect(result.title, 'Session Expired');
      expect(result.message, 'jwt expired');
      expect(result.tip, contains('log in again'));
    });

    test('Maps 500 Internal Error to polite service busy tip', () {
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/analytics'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/analytics'),
        ),
      );

      final result = ErrorMapper.map(dioErr);
      expect(result.title, 'Service Temporarily Busy');
      expect(result.tip, contains('Your data is safe'));
    });
  });
}
