import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(String identifier, String password);
  Future<UserModel> getMe();
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otp, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<LoginResponseModel> login(String identifier, String password) async {
    final response = await client.post(
      ApiEndpoints.login,
      data: {
        'identifier': identifier.trim(),
        'password': password,
      },
    );
    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getMe() async {
    final response = await client.get(ApiEndpoints.getMe);
    final payload = (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>)
        ? response['data'] as Map<String, dynamic>
        : (response as Map<String, dynamic>);
    return UserModel.fromJson(payload);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await client.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword) async {
    final response = await client.post(
      ApiEndpoints.firstLoginSetup,
      data: {
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await client.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
    );
  }

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await client.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
  }
}
