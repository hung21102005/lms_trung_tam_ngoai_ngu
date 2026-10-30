import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/network/api_exception.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<FirstLoginSetupSubmittedEvent>(_onFirstLoginSetupSubmitted);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(UnauthenticatedState());
      return;
    }

    try {
      final user = await authRepository.getMe();
      if (!user.hasValidRole) {
        await authRepository.logout();
        emit(UnauthenticatedState());
        return;
      }
      emit(AuthenticatedState(
        user: user,
        requiresPasswordChange: user.isFirstLogin,
      ));
    } catch (_) {
      // Thử dùng cache offline nếu có và hợp lệ
      final cachedUser = await authRepository.getSavedUser();
      if (cachedUser != null && cachedUser.hasValidRole) {
        emit(AuthenticatedState(
          user: cachedUser,
          requiresPasswordChange: cachedUser.isFirstLogin,
        ));
      } else {
        await authRepository.logout();
        emit(UnauthenticatedState());
      }
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final response = await authRepository.login(
        event.identifier,
        event.password,
      );

      UserEntity resolvedUser = response.user;
      if (!resolvedUser.hasValidRole) {
        try {
          resolvedUser = await authRepository.getMe();
        } catch (_) {}
      }

      if (!resolvedUser.hasValidRole) {
        await authRepository.logout();
        emit(const AuthFailureState(
          errorMessage: 'Không xác định được vai trò tài khoản. Vui lòng liên hệ quản trị viên.',
        ));
        return;
      }

      emit(AuthenticatedState(
        user: resolvedUser,
        requiresPasswordChange: response.requiresPasswordChange,
      ));
    } on ApiException catch (e) {
      emit(AuthFailureState(errorMessage: e.message));
    } catch (e) {
      emit(AuthFailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    await authRepository.logout();
    emit(UnauthenticatedState());
  }

  Future<void> _onFirstLoginSetupSubmitted(
    FirstLoginSetupSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final previousUser =
        state is AuthenticatedState ? (state as AuthenticatedState).user : null;
    emit(AuthLoadingState());
    try {
      final response = await authRepository.firstLoginSetup(
        event.newPassword,
        event.confirmPassword,
      );

      UserEntity resolvedUser = response.user.mergeWithFallback(previousUser);
      if (!resolvedUser.hasValidRole) {
        try {
          final freshUser = await authRepository.getMe();
          if (freshUser is UserModel) {
            resolvedUser = freshUser.mergeWithFallback(previousUser);
          } else {
            resolvedUser = freshUser;
          }
        } catch (_) {}
      }

      if (!resolvedUser.hasValidRole) {
        await authRepository.logout();
        emit(const AuthFailureState(
          errorMessage:
              'Không xác định được vai trò tài khoản sau khi kích hoạt. Vui lòng đăng nhập lại bằng mật khẩu mới.',
        ));
        return;
      }

      emit(AuthenticatedState(
        user: resolvedUser,
        requiresPasswordChange: false,
      ));
    } on ApiException catch (e) {
      emit(AuthFailureState(errorMessage: e.message));
    } catch (e) {
      emit(AuthFailureState(errorMessage: e.toString()));
    }
  }
}
