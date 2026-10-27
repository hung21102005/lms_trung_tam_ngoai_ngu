import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? fullName;
  final String? phone;
  final String? address;
  final String? gender;
  final String? dateOfBirth;
  final String? avatarUrl;

  const UpdateProfileEvent({
    this.fullName,
    this.phone,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [fullName, phone, address, gender, dateOfBirth, avatarUrl];
}

class ChangePasswordSubmittedEvent extends ProfileEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordSubmittedEvent({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}
