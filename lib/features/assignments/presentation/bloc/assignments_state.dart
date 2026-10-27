import 'package:equatable/equatable.dart';

import '../../data/models/assignment_model.dart';

abstract class AssignmentsState extends Equatable {
  const AssignmentsState();

  @override
  List<Object?> get props => [];
}

class AssignmentsInitialState extends AssignmentsState {}

class AssignmentsLoadingState extends AssignmentsState {}

class ClassAssignmentsLoadedState extends AssignmentsState {
  final List<AssignmentModel> assignments;

  const ClassAssignmentsLoadedState(this.assignments);

  @override
  List<Object?> get props => [assignments];
}

class AssignmentDetailLoadedState extends AssignmentsState {
  final AssignmentModel assignment;
  final bool isSubmitting;
  final String? successMessage;

  const AssignmentDetailLoadedState({
    required this.assignment,
    this.isSubmitting = false,
    this.successMessage,
  });

  AssignmentDetailLoadedState copyWith({
    AssignmentModel? assignment,
    bool? isSubmitting,
    String? successMessage,
  }) {
    return AssignmentDetailLoadedState(
      assignment: assignment ?? this.assignment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [assignment, isSubmitting, successMessage];
}

class AssignmentSubmissionsLoadedState extends AssignmentsState {
  final AssignmentSubmissionsResponseModel data;
  final bool isGrading;
  final String? successMessage;

  const AssignmentSubmissionsLoadedState({
    required this.data,
    this.isGrading = false,
    this.successMessage,
  });

  AssignmentSubmissionsLoadedState copyWith({
    AssignmentSubmissionsResponseModel? data,
    bool? isGrading,
    String? successMessage,
  }) {
    return AssignmentSubmissionsLoadedState(
      data: data ?? this.data,
      isGrading: isGrading ?? this.isGrading,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [data, isGrading, successMessage];
}

class AssignmentOperationSuccessState extends AssignmentsState {
  final String message;

  const AssignmentOperationSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class AssignmentsErrorState extends AssignmentsState {
  final String message;

  const AssignmentsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
