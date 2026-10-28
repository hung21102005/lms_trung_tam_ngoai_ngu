import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_datasource.dart';
import '../models/course_model.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  final CoursesRemoteDataSource remoteDataSource;

  CoursesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) {
    return remoteDataSource.getCourses(
      search: search,
      language: language,
      isActive: isActive,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<CourseModel> getCourseDetail(String id) {
    return remoteDataSource.getCourseDetail(id);
  }

  @override
  Future<CourseModel> createCourse({
    required String code,
    required String title,
    String? description,
    String? targetAudience,
    String language = 'English',
    String? thumbnailUrl,
  }) {
    return remoteDataSource.createCourse(
      code: code,
      title: title,
      description: description,
      targetAudience: targetAudience,
      language: language,
      thumbnailUrl: thumbnailUrl,
    );
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
  }) {
    return remoteDataSource.updateCourse(
      id,
      code: code,
      title: title,
      description: description,
      targetAudience: targetAudience,
      language: language,
      thumbnailUrl: thumbnailUrl,
      isActive: isActive,
    );
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
  }) {
    return remoteDataSource.createLevel(
      courseId,
      code: code,
      name: name,
      description: description,
      order: order,
      estimatedSessions: estimatedSessions,
      tuitionFee: tuitionFee,
    );
  }

  @override
  Future<CourseLevelModel> updateLevel(
    String levelId,
    Map<String, dynamic> changes,
  ) => remoteDataSource.updateLevel(levelId, changes);

  @override
  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  }) {
    return remoteDataSource.createModule(
      levelId,
      title: title,
      order: order,
      description: description,
    );
  }

  @override
  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  }) {
    return remoteDataSource.createLesson(
      moduleId,
      title: title,
      order: order,
      content: content,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  }) {
    return remoteDataSource.createMaterial(
      lessonId,
      title: title,
      fileUrl: fileUrl,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
    );
  }
}
