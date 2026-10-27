import 'dart:convert';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Kết nối máy chủ bị quá thời gian (timeout). Vui lòng kiểm tra lại mạng.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        dynamic responseData = response?.data;

        if (responseData is String && responseData.trim().startsWith('{')) {
          try {
            responseData = jsonDecode(responseData);
          } catch (_) {}
        }

        String extractedMessage = statusCode != null ? 'Lỗi từ máy chủ ($statusCode).' : 'Đã có lỗi xảy ra từ máy chủ.';
        if (responseData is Map<String, dynamic>) {
          if (responseData['message'] is String) {
            extractedMessage = responseData['message'];
          } else if (responseData['message'] is List) {
            extractedMessage = (responseData['message'] as List).join('\n');
          } else if (responseData['error'] is String) {
            extractedMessage = responseData['error'];
          }
        } else if (responseData is String && responseData.isNotEmpty) {
          extractedMessage = responseData;
        }

        return ApiException(
          message: extractedMessage,
          statusCode: statusCode,
          data: responseData,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng Internet hoặc cấu hình Backend.',
          statusCode: 503,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Yêu cầu gọi mạng đã bị hủy.',
        );

      default:
        return ApiException(
          message: dioException.message ?? 'Lỗi không xác định khi gọi mạng.',
        );
    }
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
