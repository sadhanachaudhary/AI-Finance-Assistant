import 'package:dio/dio.dart';

class UserFriendlyError {
  final String title;
  final String message;
  final String? tip;
  final bool isNetworkIssue;

  const UserFriendlyError({
    required this.title,
    required this.message,
    this.tip,
    this.isNetworkIssue = false,
  });

  @override
  String toString() => message;
}

/// Transforms raw technical errors and DioExceptions into clear, user-friendly guidance.
class ErrorMapper {
  static UserFriendlyError map(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const UserFriendlyError(
            title: 'Connection Timed Out',
            message: 'The server took too long to respond.',
            tip: 'Please check your internet connection and try again.',
            isNetworkIssue: true,
          );

        case DioExceptionType.connectionError:
          return const UserFriendlyError(
            title: 'Network Unavailable',
            message: 'Unable to connect to the finance server.',
            tip: 'Please check your Wi-Fi or mobile data.',
            isNetworkIssue: true,
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          String? serverMessage;
          String? serverTip;

          if (responseData is Map<String, dynamic>) {
            serverMessage = responseData['message'] as String?;
            serverTip = responseData['tip'] as String?;
          }

          if (statusCode == 401) {
            return UserFriendlyError(
              title: 'Session Expired',
              message: serverMessage ?? 'Your session has expired.',
              tip: serverTip ?? 'Please log in again to securely continue.',
            );
          }

          if (statusCode == 403) {
            return UserFriendlyError(
              title: 'Access Restricted',
              message: serverMessage ?? 'You do not have permission for this action.',
              tip: serverTip ?? 'Check your account permissions in Profile.',
            );
          }

          if (statusCode == 404) {
            return UserFriendlyError(
              title: 'Item Not Found',
              message: serverMessage ?? 'The requested financial item was not found.',
              tip: serverTip ?? 'It may have been recently removed.',
            );
          }

          if (statusCode == 422 || statusCode == 400) {
            return UserFriendlyError(
              title: 'Invalid Details',
              message: serverMessage ?? 'Please check the entered information.',
              tip: serverTip ?? 'Verify all highlighted fields and try again.',
            );
          }

          if (statusCode != null && statusCode >= 500) {
            return UserFriendlyError(
              title: 'Service Temporarily Busy',
              message: serverMessage ?? 'Our servers are experiencing momentary traffic.',
              tip: serverTip ?? 'Your data is safe. Please retry in a few moments.',
            );
          }

          return UserFriendlyError(
            title: 'Request Issue',
            message: serverMessage ?? 'Unable to complete request.',
            tip: serverTip,
          );

        case DioExceptionType.cancel:
          return const UserFriendlyError(
            title: 'Cancelled',
            message: 'The request was cancelled.',
          );

        default:
          return const UserFriendlyError(
            title: 'Communication Error',
            message: 'Something went wrong while contacting the server.',
            tip: 'Please retry shortly.',
          );
      }
    }

    final errStr = error.toString();
    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup')) {
      return const UserFriendlyError(
        title: 'Offline',
        message: 'No internet connection detected.',
        tip: 'Check your network settings and retry.',
        isNetworkIssue: true,
      );
    }

    // Clean up Exception: prefix if present
    final cleanMsg = errStr.startsWith('Exception: ') ? errStr.substring(11) : errStr;

    return UserFriendlyError(
      title: 'Action Failed',
      message: cleanMsg.isNotEmpty ? cleanMsg : 'An unexpected error occurred.',
      tip: 'Please try again or restart the app.',
    );
  }
}
