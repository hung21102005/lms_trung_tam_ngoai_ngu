import '../entities/user_entity.dart';
import '../../data/models/login_response_model.dart';

abstract class AuthRepository {
  Future<LoginResponseModel> login(String identifier, String password);
  Future<UserEntity> getMe();
  Future<UserEntity?> getSavedUser();
  Future<bool> isLoggedIn();
  Future<void> logout();
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<LoginResponseModel> firstLoginSetup(String newPassword, String confirmPassword);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otp, String newPassword);
}
