import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/assignments_repository.dart';
import 'assignments_event.dart';
import 'assignments_state.dart';

class AssignmentsBloc extends Bloc<AssignmentsEvent, AssignmentsState> {
  final AssignmentsRepository repository;

  AssignmentsBloc({required this.repository})
    : super(AssignmentsInitialState()) {
    on<LoadClassAssignmentsEvent>(_onLoadClassAssignments);
    on<LoadAssignmentDetailEvent>(_onLoadAssignmentDetail);
    on<CreateAssignmentEvent>(_onCreateAssignment);
    on<SubmitAssignmentEvent>(_onSubmitAssignment);
    on<LoadAssignmentSubmissionsEvent>(_onLoadAssignmentSubmissions);
    on<GradeSubmissionEvent>(_onGradeSubmission);
  }

  Future<void> _onLoadClassAssignments(
    LoadClassAssignmentsEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    emit(AssignmentsLoadingState());
    try {
      final list = await repository.getClassAssignments(event.classId);
      emit(ClassAssignmentsLoadedState(list));
    } catch (e) {
      emit(AssignmentsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadAssignmentDetail(
    LoadAssignmentDetailEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    emit(AssignmentsLoadingState());
    try {
      final assignment = await repository.getAssignmentDetail(
        event.assignmentId,
      );
      emit(AssignmentDetailLoadedState(assignment: assignment));
    } catch (e) {
      emit(AssignmentsErrorState(e.toString()));
    }
  }

  Future<void> _onCreateAssignment(
    CreateAssignmentEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    emit(AssignmentsLoadingState());
    try {
      await repository.createAssignment(
        event.classId,
        title: event.title,
        description: event.description,
        type: event.type,
        deadline: event.deadline,
        maxScore: event.maxScore,
        attachments: event.attachments,
      );
      emit(const AssignmentOperationSuccessState('Tạo bài tập thành công!'));
    } catch (e) {
      emit(AssignmentsErrorState(e.toString()));
    }
  }

  Future<void> _onSubmitAssignment(
    SubmitAssignmentEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    if (state is AssignmentDetailLoadedState) {
      final current = state as AssignmentDetailLoadedState;
      emit(current.copyWith(isSubmitting: true));
      try {
        await repository.submitAssignment(
          event.assignmentId,
          content: event.content,
          fileUrls: event.fileUrls,
        );
        final updated = await repository.getAssignmentDetail(
          event.assignmentId,
        );
        emit(
          AssignmentDetailLoadedState(
            assignment: updated,
            isSubmitting: false,
            successMessage: 'Nộp bài tập thành công!',
          ),
        );
      } catch (e) {
        emit(current.copyWith(isSubmitting: false));
        emit(AssignmentsErrorState(e.toString()));
      }
    }
  }

  Future<void> _onLoadAssignmentSubmissions(
    LoadAssignmentSubmissionsEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    emit(AssignmentsLoadingState());
    try {
      final data = await repository.getAssignmentSubmissions(
        event.assignmentId,
      );
      emit(AssignmentSubmissionsLoadedState(data: data));
    } catch (e) {
      emit(AssignmentsErrorState(e.toString()));
    }
  }

  Future<void> _onGradeSubmission(
    GradeSubmissionEvent event,
    Emitter<AssignmentsState> emit,
  ) async {
    if (state is AssignmentSubmissionsLoadedState) {
      final current = state as AssignmentSubmissionsLoadedState;
      emit(current.copyWith(isGrading: true));
      try {
        await repository.gradeSubmission(
          event.submissionId,
          score: event.score,
          feedback: event.feedback,
        );
        final updated = await repository.getAssignmentSubmissions(
          event.assignmentId,
        );
        emit(
          AssignmentSubmissionsLoadedState(
            data: updated,
            isGrading: false,
            successMessage: 'Đã lưu điểm và nhận xét thành công!',
          ),
        );
      } catch (e) {
        emit(current.copyWith(isGrading: false));
        emit(AssignmentsErrorState(e.toString()));
      }
    }
  }
}
