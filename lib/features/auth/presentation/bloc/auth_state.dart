import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final UserEntity user;
  final bool requiresPasswordChange;

  const AuthenticatedState({
    required this.user,
    this.requiresPasswordChange = false,
  });

  @override
  List<Object?> get props => [user, requiresPasswordChange];
}

class UnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String errorMessage;

  const AuthFailureState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
