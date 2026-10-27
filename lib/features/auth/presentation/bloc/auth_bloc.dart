import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(AuthenticatedState(
        user: user,
        requiresPasswordChange: user.isFirstLogin,
      ));
    } catch (_) {
      // Thử dùng cache offline nếu có
      final cachedUser = await authRepository.getSavedUser();
      if (cachedUser != null) {
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

      emit(AuthenticatedState(
        user: response.user,
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
    emit(AuthLoadingState());
    try {
      final response = await authRepository.firstLoginSetup(
        event.newPassword,
        event.confirmPassword,
      );

      emit(AuthenticatedState(
        user: response.user,
        requiresPasswordChange: false,
      ));
    } on ApiException catch (e) {
      emit(AuthFailureState(errorMessage: e.message));
    } catch (e) {
      emit(AuthFailureState(errorMessage: e.toString()));
    }
  }
}
