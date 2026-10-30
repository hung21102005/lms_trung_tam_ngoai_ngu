import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String identifier;
  final String password;

  const LoginSubmittedEvent({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutRequestedEvent extends AuthEvent {}

class FirstLoginSetupSubmittedEvent extends AuthEvent {
  final String newPassword;
  final String confirmPassword;

  const FirstLoginSetupSubmittedEvent({
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}
