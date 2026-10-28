import 'package:equatable/equatable.dart';

import '../../data/models/attendance_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitialState extends AttendanceState {}

class AttendanceLoadingState extends AttendanceState {}

class SessionAttendanceLoadedState extends AttendanceState {
  final SessionAttendanceResponseModel data;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const SessionAttendanceLoadedState({
    required this.data,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  SessionAttendanceLoadedState copyWith({
    SessionAttendanceResponseModel? data,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
  }) {
    return SessionAttendanceLoadedState(
      data: data ?? this.data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [data, isSubmitting, successMessage, errorMessage];
}

class StudentAttendanceLoadedState extends AttendanceState {
  final StudentAttendanceHistoryResponseModel data;

  const StudentAttendanceLoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

class MakeupRequestsLoadedState extends AttendanceState {
  final List<MakeupRequestModel> requests;
  final bool isSubmitting;
  final String? successMessage;

  const MakeupRequestsLoadedState({
    required this.requests,
    this.isSubmitting = false,
    this.successMessage,
  });

  MakeupRequestsLoadedState copyWith({
    List<MakeupRequestModel>? requests,
    bool? isSubmitting,
    String? successMessage,
  }) {
    return MakeupRequestsLoadedState(
      requests: requests ?? this.requests,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [requests, isSubmitting, successMessage];
}

class AttendanceErrorState extends AttendanceState {
  final String message;

  const AttendanceErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
