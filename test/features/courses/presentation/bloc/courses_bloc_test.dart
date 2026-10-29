import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_exception.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/data/models/course_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/domain/repositories/courses_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/courses/presentation/bloc/courses_state.dart';

class FakeCoursesRepository implements CoursesRepository {
  final Map<String, CourseModel> _courses = {};
  Object? deleteError;
  Completer<void>? deleteGate;
  int deleteCalls = 0;

  void seedCourse(CourseModel course) {
    _courses[course.id] = course;
  }

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    return _courses.values.toList();
  }

  @override
  Future<CourseModel> getCourseDetail(String id) async {
    final c = _courses[id];
    if (c == null) throw Exception('Course not found');
    return c;
  }

  @override
  Future<CourseModel> createCourse({
    required String code,
    required String title,
    String? description,
    String? targetAudience,
    String language = 'English',
    String? thumbnailUrl,
  }) async {
    final newCourse = CourseModel(
      id: 'c_${_courses.length + 1}',
      code: code,
      title: title,
      description: description,
      targetAudience: targetAudience,
      language: language,
    );
    _courses[newCourse.id] = newCourse;
    return newCourse;
  }

  @override
  Future<CourseModel> updateCourse(
    String id, {
    String? code,
    String? title,
    String? description,
    String? targetAudience,
    String? language,
    String? thumbnailUrl,
    bool? isActive,
  }) async {
    final c = _courses[id]!;
    final updated = CourseModel(
      id: c.id,
      code: code ?? c.code,
      title: title ?? c.title,
      description: description ?? c.description,
      targetAudience: targetAudience ?? c.targetAudience,
      language: language ?? c.language,
      thumbnailUrl: thumbnailUrl ?? c.thumbnailUrl,
      isActive: isActive ?? c.isActive,
      publicationStatus: c.publicationStatus,
      levels: c.levels,
    );
    _courses[id] = updated;
    return updated;
  }

  @override
  Future<void> changeCourseStatus(String id, String status) async {
    final c = _courses[id]!;
    _courses[id] = CourseModel(
      id: c.id,
      code: c.code,
      title: c.title,
      description: c.description,
      publicationStatus: status,
      isActive: c.isActive,
      levels: c.levels,
    );
  }

  @override
  Future<void> confirmCourseAcademicReview(String id) async {
    final c = _courses[id]!;
    _courses[id] = CourseModel(
      id: c.id,
      code: c.code,
      title: c.title,
      description: c.description,
      publicationStatus: 'IN_REVIEW',
      isActive: c.isActive,
      levels: c.levels,
    );
  }

  @override
  Future<void> deleteCourse(String id) async {
    deleteCalls++;
    if (deleteGate != null) await deleteGate!.future;
    if (deleteError != null) throw deleteError!;
    _courses.remove(id);
  }

  @override
  Future<CourseLevelModel> createLevel(
    String courseId, {
    required String code,
    required String name,
    String? description,
    int order = 1,
    int estimatedSessions = 24,
    double tuitionFee = 0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CourseLevelModel> updateLevel(
    String levelId,
    Map<String, dynamic> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ModuleModel> updateModule(
    String id,
    Map<String, dynamic> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LessonModel> updateLesson(
    String id,
    Map<String, dynamic> changes,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LessonMaterialModel> uploadLessonMaterial(
    String lessonId, {
    required String title,
    required String fileName,
    required Uint8List bytes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> validateCoursePublication(
    String courseId,
  ) async {
    return {'isReady': true, 'blockers': <String>[]};
  }
}

void main() {
  late FakeCoursesRepository repository;
  late CoursesBloc coursesBloc;

  const sampleCourse = CourseModel(
    id: 'course-01',
    code: 'TEST-01',
    title: 'Khóa học Thử nghiệm 01',
    publicationStatus: 'DRAFT',
    isActive: false,
  );

  setUp(() {
    repository = FakeCoursesRepository();
    repository.seedCourse(sampleCourse);
    coursesBloc = CoursesBloc(repository: repository);
  });

  tearDown(() {
    coursesBloc.close();
  });

  test('FetchCourses emits CoursesLoaded with seeded courses', () async {
    final expectedStates = [
      CoursesLoading(),
      const CoursesLoaded(courses: [sampleCourse]),
    ];

    expectLater(coursesBloc.stream, emitsInOrder(expectedStates));

    coursesBloc.add(const FetchCourses());
  });

  test('FetchCourseDetail emits CourseDetailLoaded', () async {
    final expectedStates = [
      CourseDetailLoading(),
      const CourseDetailLoaded(sampleCourse),
    ];

    expectLater(coursesBloc.stream, emitsInOrder(expectedStates));

    coursesBloc.add(const FetchCourseDetail('course-01'));
  });

  test('ChangeCoursePublicationStatusEvent emits CourseDetailLoaded and CourseOperationSuccess with updated course', () async {
    const publishedCourse = CourseModel(
      id: 'course-01',
      code: 'TEST-01',
      title: 'Khóa học Thử nghiệm 01',
      publicationStatus: 'PUBLISHED',
      isActive: false,
    );

    final expectedStates = [
      const CourseDetailLoaded(publishedCourse),
      const CourseOperationSuccess(
        'Đã phê duyệt và công bố khóa học lên website',
        data: publishedCourse,
        course: publishedCourse,
      ),
    ];

    expectLater(coursesBloc.stream, emitsInOrder(expectedStates));

    coursesBloc.add(
      const ChangeCoursePublicationStatusEvent(
        courseId: 'course-01',
        status: 'PUBLISHED',
      ),
    );
  });

  test('ToggleCourseActiveEvent emits CourseDetailLoaded and CourseOperationSuccess', () async {
    const activatedCourse = CourseModel(
      id: 'course-01',
      code: 'TEST-01',
      title: 'Khóa học Thử nghiệm 01',
      publicationStatus: 'DRAFT',
      isActive: true,
    );

    final expectedStates = [
      const CourseDetailLoaded(activatedCourse),
      const CourseOperationSuccess(
        'Đã kích hoạt khóa học để đào tạo & mở lớp',
        data: activatedCourse,
        course: activatedCourse,
      ),
    ];

    expectLater(coursesBloc.stream, emitsInOrder(expectedStates));

    coursesBloc.add(
      const ToggleCourseActiveEvent(courseId: 'course-01', isActive: true),
    );
  });

  test('DeleteCourseEvent removes course from cache and emits CourseOperationSuccess followed by CoursesLoaded', () async {
    // First load courses so cache has course-01
    coursesBloc.add(const FetchCourses());
    await Future.delayed(const Duration(milliseconds: 50));

    final expectedStates = [
      const CourseOperationSuccess('Đã xóa vĩnh viễn khóa học thành công'),
      const CoursesLoaded(courses: []),
    ];

    expectLater(coursesBloc.stream, emitsInOrder(expectedStates));

    coursesBloc.add(const DeleteCourseEvent('course-01'));
  });

  for (final status in [404, 403, 409, 500]) {
    test(
      'failed DELETE $status preserves loaded courses and filters',
      () async {
        coursesBloc.add(
          const FetchCourses(search: 'TEST', language: 'English'),
        );
        await coursesBloc.stream.firstWhere((state) => state is CoursesLoaded);
        repository.deleteError = ApiException(
          message: status == 409
              ? 'Khóa đã có lớp học liên kết'
              : 'Cannot DELETE /api/v1/courses/course-01',
          statusCode: status,
        );

        coursesBloc.add(const DeleteCourseEvent('course-01'));
        final failure = await coursesBloc.stream.firstWhere(
          (state) => state is CourseMutationFailure,
        ) as CourseMutationFailure;

        expect(failure.courses.map((course) => course.id), ['course-01']);
        expect(failure.searchQuery, 'TEST');
        expect(failure.selectedLanguage, 'English');
        expect(
          failure.message,
          status == 409
              ? 'Khóa đã có lớp học liên kết'
              : status == 403
              ? 'Bạn không có quyền xóa khóa học này.'
              : 'Không thể xóa khóa học này. Vui lòng kiểm tra trạng thái và các lớp liên kết.',
        );
        expect(repository.deleteCalls, 1);
      },
    );
  }

  test('duplicate delete taps send one request', () async {
    coursesBloc.add(const FetchCourses());
    await coursesBloc.stream.firstWhere((state) => state is CoursesLoaded);
    repository.deleteGate = Completer<void>();

    coursesBloc.add(const DeleteCourseEvent('course-01'));
    coursesBloc.add(const DeleteCourseEvent('course-01'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.deleteCalls, 1);

    repository.deleteGate!.complete();
    await coursesBloc.stream.firstWhere(
      (state) => state is CoursesLoaded && state.courses.isEmpty,
    );
    expect(repository.deleteCalls, 1);
  });
}
