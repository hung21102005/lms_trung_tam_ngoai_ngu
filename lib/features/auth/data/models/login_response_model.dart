import 'user_model.dart';

class LoginResponseModel {
  final bool requiresPasswordChange;
  final String message;
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const LoginResponseModel({
    required this.requiresPasswordChange,
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;
    return LoginResponseModel(
      requiresPasswordChange: payload['requiresPasswordChange'] as bool? ?? false,
      message: payload['message'] as String? ?? 'Đăng nhập thành công',
      accessToken: payload['accessToken'] as String? ?? '',
      refreshToken: payload['refreshToken'] as String? ?? '',
      user: UserModel.fromJson(payload['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
