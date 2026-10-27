import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getMyProfile();

  Future<UserEntity> updateProfile({
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
