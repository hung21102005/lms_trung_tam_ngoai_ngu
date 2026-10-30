import 'dart:typed_data';

import '../../data/models/course_model.dart';

abstract class CoursesRepository {
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  });

  Future<CourseModel> getCourseDetail(String id);

  Future<CourseModel> createCourse({
    required String code,
    required String title,
    String? description,
    String? targetAudience,
    String language = 'English',
    String? thumbnailUrl,
  });

  Future<CourseModel> updateCourse(
    String id, {
    String? code,
    String? title,
    String? description,
    String? targetAudience,
    String? language,
    String? thumbnailUrl,
    bool? isActive,
  });

  Future<CourseLevelModel> createLevel(
    String courseId, {
    required String code,
    required String name,
    String? description,
    int order = 1,
    int estimatedSessions = 24,
    double tuitionFee = 0,
  });

  Future<CourseLevelModel> updateLevel(
    String levelId,
    Map<String, dynamic> changes,
  );

  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  });

  Future<ModuleModel> updateModule(String id, Map<String, dynamic> changes);

  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  });

  Future<LessonModel> updateLesson(String id, Map<String, dynamic> changes);

  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  });

  Future<LessonMaterialModel> uploadLessonMaterial(
    String lessonId, {
    required String title,
    required String fileName,
    required Uint8List bytes,
  });

  Future<Map<String, dynamic>> validateCoursePublication(String id);

  Future<void> changeCourseStatus(String id, String status);

  Future<void> confirmCourseAcademicReview(String id);

  Future<void> deleteCourse(String id);
}
