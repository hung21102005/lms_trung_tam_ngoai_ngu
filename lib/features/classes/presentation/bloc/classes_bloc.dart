import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/class_model.dart';
import '../../domain/repositories/classes_repository.dart';
import '../class_deletion_message.dart';
import 'classes_event.dart';
import 'classes_state.dart';

class ClassesBloc extends Bloc<ClassesEvent, ClassesState> {
  final ClassesRepository repository;

  List<ClassModel> _cachedClasses = const [];
  final Map<String, ClassModel> _cachedDetails = {};
  final Map<String, ClassModel> _recentlyCreatedClasses = {};
  String _selectedStatus = 'ALL';
  String? _selectedBranchId;
  String _searchQuery = '';
  int _fetchClassesRequestId = 0;
  int _scheduleRequestId = 0;
  bool _isCreatingClass = false;
  final Set<String> _deletingClassIds = {};

  List<ClassModel> get cachedClasses => List.unmodifiable(_cachedClasses);

  ClassModel? getCachedDetail(String id) => _cachedDetails[id];

  bool get isCreatingClass => _isCreatingClass;

  ClassesBloc({required this.repository}) : super(ClassesInitial()) {
    on<FetchClasses>(_onFetchClasses);
    on<FetchClassDetail>(_onFetchClassDetail);
    on<FetchMyClasses>(_onFetchMyClasses);
    on<FetchMySchedule>(_onFetchMySchedule);
    on<CreateClassEvent>(_onCreateClass);
    on<UpdateClassEvent>(_onUpdateClass);
    on<DeleteClassEvent>(_onDeleteClass);
    on<EnrollStudentEvent>(_onEnrollStudent);
    on<RemoveStudentEvent>(_onRemoveStudent);
    on<UpdateSessionEvent>(_onUpdateSession);
  }

  ClassesLoaded _buildLoadedState() {
    return ClassesLoaded(
      classes: List<ClassModel>.unmodifiable(_cachedClasses),
      selectedStatus: _selectedStatus,
      selectedBranchId: _selectedBranchId,
      searchQuery: _searchQuery,
    );
  }

  void _upsertCachedClass(
    ClassModel item, {
    bool prepend = false,
    bool fromDetail = false,
  }) {
    final next = List<ClassModel>.from(_cachedClasses);
    final idx = next.indexWhere((c) => c.id == item.id);
    if (idx != -1) {
      final existing = next[idx];
      final merged = item.copyWith(
        courseTitle: item.courseTitle ?? existing.courseTitle,
        courseCode: item.courseCode ?? existing.courseCode,
        levelName: item.levelName ?? existing.levelName,
        branchName: item.branchName ?? existing.branchName,
        roomName: item.roomName ?? existing.roomName,
        mainTeacherName: item.mainTeacherName ?? existing.mainTeacherName,
        studentsCount: fromDetail
            ? item.students.length
            : (item.studentsCount > 0 || item.students.isNotEmpty
                  ? item.studentsCount
                  : existing.studentsCount),
        sessionsCount: fromDetail
            ? item.sessions.length
            : (item.sessionsCount > 0 || item.sessions.isNotEmpty
                  ? item.sessionsCount
                  : existing.sessionsCount),
        students: item.students.isNotEmpty ? item.students : existing.students,
        sessions: item.sessions.isNotEmpty ? item.sessions : existing.sessions,
      );
      next[idx] = merged;
      if (_recentlyCreatedClasses.containsKey(item.id)) {
        _recentlyCreatedClasses[item.id] = merged;
      }
      _cachedClasses = List<ClassModel>.unmodifiable(next);
    } else if (prepend) {
      next.insert(0, item);
      _cachedClasses = List<ClassModel>.unmodifiable(next);
    }
  }

  void _removeCachedClass(String classId) {
    _cachedClasses = List<ClassModel>.unmodifiable(
      _cachedClasses.where((c) => c.id != classId),
    );
    _cachedDetails.remove(classId);
    _recentlyCreatedClasses.remove(classId);
  }

  /// Thực hiện cập nhật lớp qua repository và đồng bộ ngay lập tức cache + state.
  Future<ClassModel> updateClassAndSync(
    String id, {
    String? code,
    String? name,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String? status,
    String? startDate,
    List<String>? scheduleDays,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async {
    final updated = await repository.updateClass(
      id,
      code: code,
      name: name,
      roomId: roomId,
      mainTeacherId: mainTeacherId,
      assistantTeacherId: assistantTeacherId,
      status: status,
      startDate: startDate,
      scheduleDays: scheduleDays,
      startTime: startTime,
      endTime: endTime,
      maxCapacity: maxCapacity,
      tuitionFee: tuitionFee,
      registrationOpenAt: registrationOpenAt,
      registrationCloseAt: registrationCloseAt,
      notes: notes,
    );
    _upsertCachedClass(updated);
    if (_cachedDetails.containsKey(id)) {
      final prev = _cachedDetails[id]!;
      _cachedDetails[id] = prev.copyWith(
        name: updated.name,
        status: updated.status,
        maxCapacity: updated.maxCapacity,
        tuitionFee: updated.tuitionFee,
        registrationOpenAt: updated.registrationOpenAt,
        registrationCloseAt: updated.registrationCloseAt,
        notes: updated.notes,
      );
    }
    if (!isClosed) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(_buildLoadedState());
      add(
        FetchClasses(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          status: _selectedStatus,
          branchId: _selectedBranchId,
          refresh: true,
        ),
      );
    }
    return updated;
  }

  /// Thực hiện xóa lớp qua repository và loại bỏ ngay khỏi cache + state khi thành công.
  Future<void> deleteClassAndSync(String id) async {
    if (_deletingClassIds.contains(id)) return;
    _deletingClassIds.add(id);
    try {
      await repository.deleteClass(id);
      _removeCachedClass(id);
      if (!isClosed) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(_buildLoadedState());
      }
    } finally {
      _deletingClassIds.remove(id);
    }
  }

  Future<void> _onFetchClasses(
    FetchClasses event,
    Emitter<ClassesState> emit,
  ) async {
    final requestId = ++_fetchClassesRequestId;
    if (!event.refresh && state is! ClassesLoaded && _cachedClasses.isEmpty) {
      emit(ClassesLoading());
    }
    try {
      final effectiveStatus = event.status ?? _selectedStatus;
      final statusParam = effectiveStatus == 'ALL' ? null : effectiveStatus;
      final classes = await repository.getClasses(
        search: event.search,
        status: statusParam,
        branchId: event.branchId,
        courseId: event.courseId,
      );
      if (requestId != _fetchClassesRequestId || emit.isDone) return;

      final merged = List<ClassModel>.from(classes);
      for (final created in _recentlyCreatedClasses.values) {
        final matchesStatus =
            statusParam == null || created.status == statusParam;
        final matchesBranch =
            event.branchId == null || created.branchId == event.branchId;
        final matchesCourse =
            event.courseId == null || created.courseId == event.courseId;
        final q = (event.search ?? '').trim().toLowerCase();
        final matchesSearch =
            q.isEmpty ||
            created.code.toLowerCase().contains(q) ||
            created.name.toLowerCase().contains(q);
        if (matchesStatus &&
            matchesBranch &&
            matchesCourse &&
            matchesSearch &&
            merged.every((c) => c.id != created.id)) {
          merged.insert(0, created);
        }
      }

      _cachedClasses = List<ClassModel>.unmodifiable(merged);
      _selectedStatus = effectiveStatus;
      _selectedBranchId = event.branchId;
      _searchQuery = event.search ?? '';

      emit(_buildLoadedState());
    } catch (e) {
      if (requestId != _fetchClassesRequestId || emit.isDone) return;
      if (event.refresh && _cachedClasses.isNotEmpty) {
        emit(_buildLoadedState());
        return;
      }
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchClassDetail(
    FetchClassDetail event,
    Emitter<ClassesState> emit,
  ) async {
    if (!_cachedDetails.containsKey(event.id)) {
      emit(ClassDetailLoading());
    }
    try {
      final classDetail = await repository.getClassDetail(event.id);
      _cachedDetails[event.id] = classDetail;
      _upsertCachedClass(classDetail, fromDetail: true);
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

      emit(
        MyScheduleLoaded(
          sessions: sessions,
          selectedDay: event.fromDate ?? now,
        ),
      );
    } catch (e) {
      if (requestId != _scheduleRequestId || emit.isDone) return;
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateClass(
    CreateClassEvent event,
    Emitter<ClassesState> emit,
  ) async {
    if (_isCreatingClass) return;
    _isCreatingClass = true;
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
        registrationOpenAt: event.registrationOpenAt,
        registrationCloseAt: event.registrationCloseAt,
        notes: event.notes,
      );
      final normalizedCreated =
          created.sessionsCount == 0 && created.totalSessions > 0
          ? created.copyWith(sessionsCount: created.totalSessions)
          : created;
      if (normalizedCreated.id.isNotEmpty) {
        _recentlyCreatedClasses[normalizedCreated.id] = normalizedCreated;
      }
      _upsertCachedClass(normalizedCreated, prepend: true);
      emit(
        ClassOperationSuccess(
          'Đã tạo lớp và sinh lịch học thành công',
          data: normalizedCreated,
        ),
      );
      emit(_buildLoadedState());
      add(
        FetchClasses(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          status: _selectedStatus,
          branchId: _selectedBranchId,
          refresh: true,
        ),
      );
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
      if (_cachedClasses.isNotEmpty) {
        emit(_buildLoadedState());
      }
    } finally {
      _isCreatingClass = false;
    }
  }

  Future<void> _onUpdateClass(
    UpdateClassEvent event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      final updated = await repository.updateClass(
        event.id,
        code: event.code,
        name: event.name,
        roomId: event.roomId,
        mainTeacherId: event.mainTeacherId,
        assistantTeacherId: event.assistantTeacherId,
        status: event.status,
        startDate: event.startDate,
        scheduleDays: event.scheduleDays,
        startTime: event.startTime,
        endTime: event.endTime,
        maxCapacity: event.maxCapacity,
        tuitionFee: event.tuitionFee,
        registrationOpenAt: event.registrationOpenAt,
        registrationCloseAt: event.registrationCloseAt,
        notes: event.notes,
      );
      _upsertCachedClass(updated);
      if (_cachedDetails.containsKey(event.id)) {
        try {
          final detail = await repository.getClassDetail(event.id);
          _cachedDetails[event.id] = detail;
          _upsertCachedClass(detail, fromDetail: true);
          emit(ClassDetailLoaded(detail));
        } catch (_) {
          final prevDetail = _cachedDetails[event.id]!;
          final mergedDetail = prevDetail.copyWith(
            name: updated.name,
            status: updated.status,
            maxCapacity: updated.maxCapacity,
            tuitionFee: updated.tuitionFee,
            registrationOpenAt: updated.registrationOpenAt,
            registrationCloseAt: updated.registrationCloseAt,
            notes: updated.notes,
          );
          _cachedDetails[event.id] = mergedDetail;
          emit(ClassDetailLoaded(mergedDetail));
        }
      }
      emit(
        ClassOperationSuccess(
          event.successMessage ?? 'Đã cập nhật thông tin lớp học thành công',
          data: updated,
        ),
      );
      if (_cachedClasses.isNotEmpty) {
        emit(_buildLoadedState());
      }
      add(
        FetchClasses(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          status: _selectedStatus,
          branchId: _selectedBranchId,
          refresh: true,
        ),
      );
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
      if (_cachedClasses.isNotEmpty) {
        emit(_buildLoadedState());
      }
    }
  }

  Future<void> _onDeleteClass(
    DeleteClassEvent event,
    Emitter<ClassesState> emit,
  ) async {
    if (_deletingClassIds.contains(event.id)) return;
    _deletingClassIds.add(event.id);
    try {
      await repository.deleteClass(event.id);
      _removeCachedClass(event.id);
      emit(
        ClassOperationSuccess(
          'Đã xóa lớp học thành công',
          data: event.id,
        ),
      );
      emit(_buildLoadedState());
    } catch (e) {
      emit(ClassesError(classDeletionMessage(e)));
      if (_cachedClasses.isNotEmpty) {
        emit(_buildLoadedState());
      }
    } finally {
      _deletingClassIds.remove(event.id);
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
      final classDetail = await repository.getClassDetail(event.classId);
      _cachedDetails[event.classId] = classDetail;
      _upsertCachedClass(classDetail, fromDetail: true);
      emit(
        ClassOperationSuccess(
          'Ghi danh học viên vào lớp thành công',
          data: classDetail,
        ),
      );
      emit(ClassDetailLoaded(classDetail));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
      final existingDetail = _cachedDetails[event.classId];
      if (existingDetail != null) {
        emit(ClassDetailLoaded(existingDetail));
      }
    }
  }

  Future<void> _onRemoveStudent(
    RemoveStudentEvent event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      await repository.removeStudent(event.classId, event.studentId);
      final classDetail = await repository.getClassDetail(event.classId);
      _cachedDetails[event.classId] = classDetail;
      _upsertCachedClass(classDetail, fromDetail: true);
      emit(
        ClassOperationSuccess(
          'Đã xóa học viên khỏi danh sách lớp',
          data: classDetail,
        ),
      );
      emit(ClassDetailLoaded(classDetail));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
      final existingDetail = _cachedDetails[event.classId];
      if (existingDetail != null) {
        emit(ClassDetailLoaded(existingDetail));
      }
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
      final classDetail = await repository.getClassDetail(event.classId);
      _cachedDetails[event.classId] = classDetail;
      _upsertCachedClass(classDetail, fromDetail: true);
      emit(
        ClassOperationSuccess(
          'Cập nhật thông tin buổi học thành công',
          data: classDetail,
        ),
      );
      emit(ClassDetailLoaded(classDetail));
    } catch (e) {
      emit(ClassesError(e.toString().replaceAll('Exception: ', '')));
      final existingDetail = _cachedDetails[event.classId];
      if (existingDetail != null) {
        emit(ClassDetailLoaded(existingDetail));
      }
    }
  }
}
