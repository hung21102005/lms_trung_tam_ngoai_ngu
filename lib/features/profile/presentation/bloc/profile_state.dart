import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  final String? successMessage;

  const ProfileLoaded({
    required this.user,
    this.successMessage,
  });

  @override
  List<Object?> get props => [user, successMessage];
}

class ProfileUpdating extends ProfileState {
  final UserEntity currentUser;

  const ProfileUpdating({required this.currentUser});

  @override
  List<Object?> get props => [currentUser];
}

class ProfilePasswordChanging extends ProfileState {
  const ProfilePasswordChanging();
}

class ProfilePasswordChangeSuccess extends ProfileState {
  final String message;

  const ProfilePasswordChangeSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  final String message;
  final UserEntity? user;

  const ProfileError({
    required this.message,
    this.user,
  });

  @override
  List<Object?> get props => [message, user];
}
