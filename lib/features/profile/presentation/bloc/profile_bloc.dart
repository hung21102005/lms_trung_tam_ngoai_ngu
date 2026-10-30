import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ChangePasswordSubmittedEvent>(_onChangePassword);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final user = await repository.getMyProfile();
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state is ProfileLoaded ? (state as ProfileLoaded).user : null;
    if (current != null) {
      emit(ProfileUpdating(currentUser: current));
    } else {
      emit(const ProfileLoading());
    }

    try {
      final updatedUser = await repository.updateProfile(
        fullName: event.fullName,
        phone: event.phone,
        address: event.address,
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
        avatarUrl: event.avatarUrl,
      );
      emit(ProfileLoaded(
        user: updatedUser,
        successMessage: 'Cập nhật thông tin cá nhân thành công!',
      ));
    } catch (e) {
      emit(ProfileError(
        message: e.toString(),
        user: current,
      ));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordSubmittedEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfilePasswordChanging());
    try {
      await repository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );
      emit(const ProfilePasswordChangeSuccess(
        message: 'Đổi mật khẩu thành công. Hãy sử dụng mật khẩu mới cho lần đăng nhập sau!',
      ));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
