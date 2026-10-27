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
  }

  Future<void> _onFetchCourses(
    FetchCourses event,
    Emitter<CoursesState> emit,
  ) async {
    if (!event.refresh && state is! CoursesLoaded) {
      emit(CoursesLoading());
    }
    try {
      final language = event.language == 'All' || event.language == 'Tất cả' ? null : event.language;
      final courses = await repository.getCourses(
        search: event.search,
        language: language,
      );
      emit(CoursesLoaded(
        courses: courses,
        selectedLanguage: event.language ?? 'All',
        searchQuery: event.search ?? '',
      ));
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
}
