class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
    );
  }

  factory ApiResponse.failure({
    required String message,
    int? statusCode,
    T? data,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }
}
