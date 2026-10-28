import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/courses_repository.dart';
import 'courses_event.dart';
import 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final CoursesRepository repository;

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
  }

  Future<void> _onFetchCourses(
    FetchCourses event,
    Emitter<CoursesState> emit,
  ) async {
    if (!event.refresh && state is! CoursesLoaded) {
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
      emit(
        CoursesLoaded(
          courses: courses,
          selectedLanguage: event.language ?? 'All',
          searchQuery: event.search ?? '',
        ),
      );
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchCourseDetail(
    FetchCourseDetail event,
    Emitter<CoursesState> emit,
  ) async {
    emit(CourseDetailLoading());
    try {
      final course = await repository.getCourseDetail(event.id);
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
      emit(CourseOperationSuccess('Đã tạo khóa học thành công', data: created));
      add(const FetchCourses(refresh: true));
    } catch (e) {
      emit(CoursesError(e.toString().replaceAll('Exception: ', '')));
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
      emit(const CourseOperationSuccess('Đã thêm cấp độ đào tạo thành công'));
      add(FetchCourseDetail(event.courseId));
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
      emit(const CourseOperationSuccess('Đã cập nhật cấp độ đào tạo'));
      add(FetchCourseDetail(event.courseId));
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
      emit(const CourseOperationSuccess('Đã cập nhật học phần'));
      add(FetchCourseDetail(event.courseId));
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
      emit(const CourseOperationSuccess('Đã cập nhật bài học'));
      add(FetchCourseDetail(event.courseId));
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
      emit(const CourseOperationSuccess('Đã thêm học phần'));
      add(FetchCourseDetail(event.courseId));
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
      emit(const CourseOperationSuccess('Đã thêm bài học'));
      add(FetchCourseDetail(event.courseId));
    } catch (error) {
      emit(CoursesError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}
