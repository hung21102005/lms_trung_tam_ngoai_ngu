import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storageService;
  final Dio dio;

  AuthInterceptor({
    required this.storageService,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Không đính kèm token cho các public auth endpoints
    final publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
      ApiEndpoints.refreshToken,
    ];

    final isPublic = publicPaths.any((path) => options.path.contains(path));

    if (!isPublic) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Xử lý tự động làm mới token khi gặp lỗi 401 Unauthorized
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiEndpoints.login) &&
        !err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Tạo một Dio instance độc lập để gọi refresh tránh bị lặp interceptor
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl.isNotEmpty ? dio.options.baseUrl : ApiEndpoints.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );

          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final dataMap = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
            final nestedData = dataMap?['data'] is Map<String, dynamic> ? dataMap!['data'] as Map<String, dynamic> : null;
            final newAccessToken = (nestedData?['accessToken'] ?? dataMap?['accessToken']) as String?;
            final newRefreshToken = (nestedData?['refreshToken'] ?? dataMap?['refreshToken']) as String?;

            if (newAccessToken != null) {
              await storageService.saveAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await storageService.saveRefreshToken(newRefreshToken);
              }

              // Gửi lại request ban đầu với accessToken mới
              final originalRequest = err.requestOptions;
              originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await dio.fetch(originalRequest);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Refresh thất bại -> xóa session
          await storageService.clearAll();
        }
      } else {
        await storageService.clearAll();
      }
    }

    return handler.next(err);
  }
}
