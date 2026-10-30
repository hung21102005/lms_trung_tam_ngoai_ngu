import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/course_model.dart';
import '../../domain/repositories/courses_repository.dart';
import '../course_deletion_message.dart';
import 'courses_event.dart';
import 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final CoursesRepository repository;

  List<CourseModel> _cachedCourses = const [];
  final Map<String, CourseModel> _cachedCourseDetails = {};
  final Map<String, CourseModel> _recentlyCreatedCourses = {};
  String _selectedLanguage = 'All';
  String _searchQuery = '';
  int _fetchCoursesRequestId = 0;
  final Set<String> _deletingCourseIds = {};

  List<CourseModel> get cachedCourses => List.unmodifiable(_cachedCourses);

  CourseModel? getCachedCourseDetail(String id) => _cachedCourseDetails[id];

  CoursesBloc({required this.repository}) : super(CoursesInitial()) {
    on<FetchCourses>(_onFetchCourses);
    on<FetchCourseDetail>(_onFetchCourseDetail);
    on<CreateCourseEvent>(_onCreateCourse);
    on<CreateCourseLevelEvent>(_onCreateCourseLevel);
    on<UpdateCourseLevelEvent>(_onUpdateCourseLevel);
    on<UpdateModuleEvent>(_onUpdateModule);
    on<UpdateLessonEvent>(_onUpdateLesson);
    on<CreateModuleEvent>(_onCreateModule);
    on<CreateLessonEvent>(_onCreateLesson);
    on<UploadLessonMaterialEvent>(_onUploadLessonMaterial);
    on<ChangeCoursePublicationStatusEvent>(_onChangeCoursePublicationStatus);
    on<ConfirmCourseAcademicReviewEvent>(_onConfirmCourseAcademicReview);
    on<ToggleCourseActiveEvent>(_onToggleCourseActive);
    on<CheckCoursePublicationEvent>(_onCheckCoursePublication);
    on<DeleteCourseEvent>(_onDeleteCourse);
  }

  CoursesLoaded _buildLoadedState() {
    return CoursesLoaded(
      courses: List<CourseModel>.unmodifiable(_cachedCourses),
      selectedLanguage: _selectedLanguage,
      searchQuery: _searchQuery,
    );
  }

  void _updateCachedCourse(CourseModel updated, {bool prepend = false}) {
    _cachedCourseDetails[updated.id] = updated;
    if (_recentlyCreatedCourses.containsKey(updated.id)) {
      _recentlyCreatedCourses[updated.id] = updated;
    }
    final next = List<CourseModel>.from(_cachedCourses);
    final idx = next.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      next[idx] = updated;
      _cachedCourses = List<CourseModel>.unmodifiable(next);
    } else if (prepend) {
      next.insert(0, updated);
      _cachedCourses = List<CourseModel>.unmodifiable(next);
    }
  }

  void _removeCachedCourse(String courseId) {
    _cachedCourses = List<CourseModel>.unmodifiable(
      _cachedCourses.where((c) => c.id != courseId),
    );
    _cachedCourseDetails.remove(courseId);
    _recentlyCreatedCourses.remove(courseId);
  }

  void _emitSyncedCourseMutation(
    Emitter<CoursesState> emit, {
    required CourseModel updatedCourse,
    required String message,
  }) {
    _updateCachedCourse(updatedCourse);
    emit(CourseDetailLoaded(updatedCourse));
    emit(
      CourseOperationSuccess(
        message,
        data: updatedCourse,
        course: updatedCourse,
      ),
    );
    if (_cachedCourses.isNotEmpty) {
      emit(_buildLoadedState());
    }
  }

  Future<void> _onFetchCourses(
    FetchCourses event,
    Emitter<CoursesState> emit,
  ) async {
    final requestId = ++_fetchCoursesRequestId;
    if (!event.refresh && state is! CoursesLoaded && _cachedCourses.isEmpty) {
      emit(CoursesLoading());
    }
    try {
      final language = event.language == 'All' || event.language == 'Tất cả'
          ? null
          : event.language;
      final courses = await repository.getCourses(
        search: event.search,
        language: language,
      );
      if (requestId != _fetchCoursesRequestId || emit.isDone) return;

      final merged = List<CourseModel>.from(courses);
      for (final created in _recentlyCreatedCourses.values) {
        if (merged.every((c) => c.id != created.id)) {
          merged.insert(0, created);
        }
      }
      _cachedCourses = List<CourseModel>.unmodifiable(merged);
      _selectedLanguage = event.language ?? 'All';
      _searchQuery = event.search ?? '';
      emit(_buildLoadedState());
    } catch (e) {
      if (requestId != _fetchCoursesRequestId || emit.isDone) return;
      if (event.refresh && _cachedCourses.isNotEmpty) {
        emit(_buildLoadedState());
        return;
      }
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchCourseDetail(
    FetchCourseDetail event,
    Emitter<CoursesState> emit,
  ) async {
    if (!_cachedCourseDetails.containsKey(event.id)) {
      emit(CourseDetailLoading());
    }
    try {
      final course = await repository.getCourseDetail(event.id);
      _updateCachedCourse(course);
      emit(CourseDetailLoaded(course));
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateCourse(
    CreateCourseEvent event,
    Emitter<CoursesState> emit,
  ) async {
    emit(CoursesLoading());
    try {
      final created = await repository.createCourse(
        code: event.code,
        title: event.title,
        description: event.description,
        targetAudience: event.targetAudience,
        language: event.language,
      );
      if (created.id.isNotEmpty) {
        _recentlyCreatedCourses[created.id] = created;
      }
      _updateCachedCourse(created, prepend: true);
      emit(CourseOperationSuccess('Đã tạo khóa học thành công', data: created, course: created));
      emit(_buildLoadedState());
      add(const FetchCourses(refresh: true));
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
      if (_cachedCourses.isNotEmpty) {
        emit(_buildLoadedState());
      }
    }
  }

  Future<void> _onCreateCourseLevel(
    CreateCourseLevelEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.createLevel(
        event.courseId,
        code: event.code,
        name: event.name,
        description: event.description,
        order: event.order,
        estimatedSessions: event.estimatedSessions,
        tuitionFee: event.tuitionFee,
      );
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã thêm cấp độ đào tạo thành công',
      );
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCourseLevel(
    UpdateCourseLevelEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.updateLevel(event.levelId, event.changes);
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã cập nhật cấp độ đào tạo',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateModule(
    UpdateModuleEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.updateModule(event.moduleId, event.changes);
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã cập nhật học phần',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateLesson(
    UpdateLessonEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.updateLesson(event.lessonId, event.changes);
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã cập nhật bài học',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateModule(
    CreateModuleEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.createModule(
        event.levelId,
        title: event.values['title'] as String,
        order: event.values['order'] as int,
        description: event.values['description'] as String?,
      );
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã thêm học phần',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateLesson(
    CreateLessonEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.createLesson(
        event.moduleId,
        title: event.values['title'] as String,
        order: event.values['order'] as int,
        content: event.values['content'] as String?,
        durationMinutes: event.values['durationMinutes'] as int,
      );
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã thêm bài học',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUploadLessonMaterial(
    UploadLessonMaterialEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.uploadLessonMaterial(
        event.lessonId,
        title: event.title,
        fileName: event.fileName,
        bytes: event.bytes,
      );
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã thêm tài liệu bài học',
      );
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onChangeCoursePublicationStatus(
    ChangeCoursePublicationStatusEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.changeCourseStatus(event.courseId, event.status);
      final label = switch (event.status) {
        'PUBLISHED' => 'Đã phê duyệt và công bố khóa học lên website',
        'IN_REVIEW' => 'Đã gửi duyệt khóa học thành công',
        'DRAFT' => 'Đã chuyển khóa học về bản nháp',
        'ARCHIVED' => 'Đã lưu trữ khóa học',
        _ => 'Đã cập nhật trạng thái khóa học',
      };
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: label,
      );
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onConfirmCourseAcademicReview(
    ConfirmCourseAcademicReviewEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.confirmCourseAcademicReview(event.courseId);
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: 'Đã xác nhận rà soát học thuật thành công',
      );
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleCourseActive(
    ToggleCourseActiveEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      await repository.updateCourse(event.courseId, isActive: event.isActive);
      final label = event.isActive
          ? 'Đã kích hoạt khóa học để đào tạo & mở lớp'
          : 'Đã tạm ngưng khóa học';
      final updatedCourse = await repository.getCourseDetail(event.courseId);
      _emitSyncedCourseMutation(
        emit,
        updatedCourse: updatedCourse,
        message: label,
      );
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCourse(
    DeleteCourseEvent event,
    Emitter<CoursesState> emit,
  ) async {
    if (!_deletingCourseIds.add(event.courseId)) return;
    try {
      await repository.deleteCourse(event.courseId);
      _removeCachedCourse(event.courseId);
      emit(const CourseOperationSuccess('Đã xóa vĩnh viễn khóa học thành công'));
      emit(CoursesLoaded(
        courses: List.from(_cachedCourses),
        selectedLanguage: _selectedLanguage,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      emit(CourseMutationFailure(
        message: courseDeletionMessage(e),
        courses: List.from(_cachedCourses),
        selectedLanguage: _selectedLanguage,
        searchQuery: _searchQuery,
      ));
    } finally {
      _deletingCourseIds.remove(event.courseId);
    }
  }

  Future<void> _onCheckCoursePublication(
    CheckCoursePublicationEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      final result = await repository.validateCoursePublication(event.courseId);
      emit(CoursePublicationCheckLoaded(
        courseId: event.courseId,
        checkResult: result,
      ));
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
