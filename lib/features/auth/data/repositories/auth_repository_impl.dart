import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<LoginResponseModel> login(String identifier, String password) async {
    final response = await remoteDataSource.login(identifier, password);

    // Lưu token và user data vào secure storage
    await storageService.saveAccessToken(response.accessToken);
    await storageService.saveRefreshToken(response.refreshToken);
    await storageService.saveUserData(response.user.toJson());

    return response;
  }

  @override
  Future<UserEntity> getMe() async {
    final user = await remoteDataSource.getMe();
    await storageService.saveUserData(user.toJson());
    return user;
  }

  @override
  Future<UserEntity?> getSavedUser() async {
    final userData = await storageService.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await storageService.clearAll();
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await remoteDataSource.changePassword(oldPassword, newPassword);
  }

  @override
  Future<LoginResponseModel> firstLoginSetup(
    String newPassword,
    String confirmPassword,
  ) async {
    final previousUser = await getSavedUser();
    final response = await remoteDataSource.firstLoginSetup(
      newPassword,
      confirmPassword,
    );

    if (response.accessToken.isNotEmpty) {
      await storageService.saveAccessToken(response.accessToken);
    }
    if (response.refreshToken.isNotEmpty) {
      await storageService.saveRefreshToken(response.refreshToken);
    }

    UserModel resolvedUser = response.user.mergeWithFallback(previousUser);
    if (!resolvedUser.hasValidRole) {
      try {
        final freshUser = await remoteDataSource.getMe();
        resolvedUser = freshUser.mergeWithFallback(resolvedUser);
      } catch (_) {
        // Nếu getMe không khả dụng (ví dụ trong môi trường test độc lập), giữ resolvedUser
      }
    }

    await storageService.saveUserData(resolvedUser.toJson());

    return LoginResponseModel(
      message: response.message,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      requiresPasswordChange: false,
      user: resolvedUser,
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await remoteDataSource.forgotPassword(email);
  }

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await remoteDataSource.resetPassword(email, otp, newPassword);
  }
}
