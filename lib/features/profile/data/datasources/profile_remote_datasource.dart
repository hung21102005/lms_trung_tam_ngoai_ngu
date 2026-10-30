import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getMyProfile();

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getMyProfile() async {
    final response = await apiClient.get(ApiEndpoints.getMe);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    throw Exception('Dữ liệu hồ sơ người dùng không hợp lệ.');
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (gender != null) body['gender'] = gender;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await apiClient.patch(
      ApiEndpoints.updateProfile,
      data: body,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    return getMyProfile();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
