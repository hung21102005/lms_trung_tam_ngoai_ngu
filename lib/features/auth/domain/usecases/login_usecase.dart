import '../repositories/auth_repository.dart';
import '../../data/models/login_response_model.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<LoginResponseModel> call(String identifier, String password) {
    return repository.login(identifier, password);
  }
}
