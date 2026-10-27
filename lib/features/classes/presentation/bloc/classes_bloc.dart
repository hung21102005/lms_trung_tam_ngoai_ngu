import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/classes_repository.dart';
import 'classes_event.dart';
import 'classes_state.dart';

class ClassesBloc extends Bloc<ClassesEvent, ClassesState> {
  final ClassesRepository repository;
  int _scheduleRequestId = 0;

  ClassesBloc({required this.repository}) : super(ClassesInitial()) {
    on<FetchClasses>(_onFetchClasses);
    on<FetchClassDetail>(_onFetchClassDetail);
    on<FetchMyClasses>(_onFetchMyClasses);
    on<FetchMySchedule>(_onFetchMySchedule);
    on<CreateClassEvent>(_onCreateClass);
    on<EnrollStudentEvent>(_onEnrollStudent);
    on<RemoveStudentEvent>(_onRemoveStudent);
    on<UpdateSessionEvent>(_onUpdateSession);
  }

  Future<void> _onFetchClasses(
    FetchClasses event,
    Emitter<ClassesState> emit,
  ) async {
    if (!event.refresh && state is! ClassesLoaded) {
      emit(ClassesLoading());
    }
    try {
      final status = event.status == 'ALL' || event.status == null ? null : event.status;
      final classes = await repository.getClasses(
        search: event.search,
        status: status,
        branchId: event.branchId,
        courseId: event.courseId,
      );
      emit(ClassesLoaded(
        classes: classes,
        selectedStatus: event.status ?? 'ALL',
        selectedBranchId: event.branchId,
        searchQuery: event.search ?? '',
      ));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchClassDetail(
    FetchClassDetail event,
    Emitter<ClassesState> emit,
  ) async {
    emit(ClassDetailLoading());
    try {
      final classDetail = await repository.getClassDetail(event.id);
      emit(ClassDetailLoaded(classDetail));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchMyClasses(
    FetchMyClasses event,
    Emitter<ClassesState> emit,
  ) async {
    emit(ClassesLoading());
    try {
      final classes = await repository.getMyClasses();
      emit(MyClassesLoaded(classes));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchMySchedule(
    FetchMySchedule event,
    Emitter<ClassesState> emit,
  ) async {
    final requestId = ++_scheduleRequestId;
    emit(MyScheduleLoading());
    try {
      final now = DateTime.now();
      final from = event.fromDate ?? DateTime(now.year, now.month, 1);
      final to = event.toDate ?? DateTime(now.year, now.month + 1, 0);

      final format = DateFormat('yyyy-MM-dd');
      final sessions = await repository.getMySchedule(
        fromDate: format.format(from),
        toDate: format.format(to),
      );

      if (requestId != _scheduleRequestId || emit.isDone) return;

      emit(MyScheduleLoaded(
        sessions: sessions,
        selectedDay: event.fromDate ?? now,
      ));
    } catch (e) {
      if (requestId != _scheduleRequestId || emit.isDone) return;
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateClass(
    CreateClassEvent event,
    Emitter<ClassesState> emit,
  ) async {
    emit(ClassesLoading());
    try {
      final created = await repository.createClass(
        code: event.code,
        name: event.name,
        courseId: event.courseId,
        levelId: event.levelId,
        branchId: event.branchId,
        roomId: event.roomId,
        mainTeacherId: event.mainTeacherId,
        assistantTeacherId: event.assistantTeacherId,
        status: event.status,
        startDate: event.startDate,
        scheduleDays: event.scheduleDays,
        startTime: event.startTime,
        endTime: event.endTime,
        totalSessions: event.totalSessions,
        maxCapacity: event.maxCapacity,
        tuitionFee: event.tuitionFee,
        notes: event.notes,
      );
      emit(ClassOperationSuccess('Đã tạo lớp và sinh lịch học thành công', data: created));
      add(const FetchClasses(refresh: true));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onEnrollStudent(
    EnrollStudentEvent event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      await repository.enrollStudent(
        event.classId,
        studentId: event.studentId,
        tuitionPaid: event.tuitionPaid,
        notes: event.notes,
      );
      emit(const ClassOperationSuccess('Ghi danh học viên vào lớp thành công'));
      add(FetchClassDetail(event.classId));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRemoveStudent(
    RemoveStudentEvent event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      await repository.removeStudent(event.classId, event.studentId);
      emit(const ClassOperationSuccess('Đã xóa học viên khỏi danh sách lớp'));
      add(FetchClassDetail(event.classId));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSession(
    UpdateSessionEvent event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      await repository.updateSessionWithTitle(
        event.sessionId,
        title: event.title,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        roomId: event.roomId,
        teacherId: event.teacherId,
        status: event.status,
        notes: event.notes,
      );
      emit(const ClassOperationSuccess('Cập nhật thông tin buổi học thành công'));
      add(FetchClassDetail(event.classId));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
