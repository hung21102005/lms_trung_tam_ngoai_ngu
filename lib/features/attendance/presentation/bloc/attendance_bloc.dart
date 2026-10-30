import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/attendance_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(AttendanceInitialState()) {
    on<LoadSessionAttendanceEvent>(_onLoadSessionAttendance);
    on<UpdateStudentStatusEvent>(_onUpdateStudentStatus);
    on<BatchMarkAttendanceEvent>(_onBatchMarkAttendance);
    on<LoadStudentAttendanceEvent>(_onLoadStudentAttendance);
    on<LoadMakeupRequestsEvent>(_onLoadMakeupRequests);
    on<CreateMakeupRequestEvent>(_onCreateMakeupRequest);
    on<UpdateMakeupRequestStatusEvent>(_onUpdateMakeupRequestStatus);
  }

  Future<void> _onLoadSessionAttendance(
    LoadSessionAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    try {
      final data = await repository.getSessionAttendance(event.sessionId);
      emit(SessionAttendanceLoadedState(data: data));
    } catch (e) {
      emit(AttendanceErrorState(e.toString()));
    }
  }

  void _onUpdateStudentStatus(
    UpdateStudentStatusEvent event,
    Emitter<AttendanceState> emit,
  ) {
    if (state is SessionAttendanceLoadedState) {
      final current = state as SessionAttendanceLoadedState;
      final updatedStudents = current.data.students.map((s) {
        if (s.studentId == event.studentId) {
          return StudentAttendanceItemModel(
            studentId: s.studentId,
            userCode: s.userCode,
            fullName: s.fullName,
            avatarUrl: s.avatarUrl,
            phone: s.phone,
            email: s.email,
            attendanceId: s.attendanceId,
            status: event.status,
            checkInTime: s.checkInTime,
            notes: event.notes ?? s.notes,
            markedAt: s.markedAt,
          );
        }
        return s;
      }).toList();

      emit(
        current.copyWith(
          data: SessionAttendanceResponseModel(
            sessionId: current.data.sessionId,
            classId: current.data.classId,
            className: current.data.className,
            classCode: current.data.classCode,
            sessionNumber: current.data.sessionNumber,
            title: current.data.title,
            date: current.data.date,
            startTime: current.data.startTime,
            endTime: current.data.endTime,
            status: current.data.status,
            summary: current.data.summary,
            students: updatedStudents,
          ),
        ),
      );
    }
  }

  Future<void> _onBatchMarkAttendance(
    BatchMarkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is SessionAttendanceLoadedState) {
      final current = state as SessionAttendanceLoadedState;
      emit(current.copyWith(isSubmitting: true));
      try {
        final data = await repository.batchMarkAttendance(
          event.sessionId,
          event.students,
        );
        emit(
          SessionAttendanceLoadedState(
            data: data,
            isSubmitting: false,
            successMessage: 'Lưu điểm danh thành công!',
          ),
        );
      } catch (e) {
        emit(current.copyWith(isSubmitting: false, errorMessage: e.toString()));
      }
    }
  }

  Future<void> _onLoadStudentAttendance(
    LoadStudentAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    try {
      final data = await repository.getStudentAttendance(event.studentId);
      emit(StudentAttendanceLoadedState(data));
    } catch (e) {
      emit(AttendanceErrorState(e.toString()));
    }
  }

  Future<void> _onLoadMakeupRequests(
    LoadMakeupRequestsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    try {
      final requests = await repository.getMakeupRequests(
        status: event.status,
        studentId: event.studentId,
      );
      emit(MakeupRequestsLoadedState(requests: requests));
    } catch (e) {
      emit(AttendanceErrorState(e.toString()));
    }
  }

  Future<void> _onCreateMakeupRequest(
    CreateMakeupRequestEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    try {
      await repository.createMakeupRequest(
        originalSessionId: event.originalSessionId,
        targetSessionId: event.targetSessionId,
        reason: event.reason,
      );
      final requests = await repository.getMakeupRequests();
      emit(
        MakeupRequestsLoadedState(
          requests: requests,
          successMessage: 'Đăng ký yêu cầu học bù thành công!',
        ),
      );
    } catch (e) {
      emit(AttendanceErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateMakeupRequestStatus(
    UpdateMakeupRequestStatusEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is MakeupRequestsLoadedState) {
      final current = state as MakeupRequestsLoadedState;
      emit(current.copyWith(isSubmitting: true));
      try {
        await repository.updateMakeupRequest(
          event.id,
          status: event.status,
          reason: event.reason,
        );
        final requests = await repository.getMakeupRequests();
        emit(
          MakeupRequestsLoadedState(
            requests: requests,
            isSubmitting: false,
            successMessage: 'Cập nhật trạng thái yêu cầu thành công!',
          ),
        );
      } catch (e) {
        emit(current.copyWith(isSubmitting: false));
        emit(AttendanceErrorState(e.toString()));
      }
    }
  }
}
