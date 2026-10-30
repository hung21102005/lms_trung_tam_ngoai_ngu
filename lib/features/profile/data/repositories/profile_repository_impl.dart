import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> getMyProfile() {
    return remoteDataSource.getMyProfile();
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarUrl,
  }) {
    return remoteDataSource.updateProfile(
      fullName: fullName,
      phone: phone,
      address: address,
      gender: gender,
      dateOfBirth: dateOfBirth,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
