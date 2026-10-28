import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/course_model.dart';

abstract class CoursesRemoteDataSource {
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

  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  });

  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  });
}

class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  final ApiClient apiClient;

  CoursesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseModel>> getCourses({
    String? search,
    String? language,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }
    if (isActive != null) queryParams['isActive'] = isActive;

    final response = await apiClient.get(
      ApiEndpoints.courses,
      queryParameters: queryParams,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((item) => CourseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((item) => CourseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<CourseModel> getCourseDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.courseDetail(id));
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is Map<String, dynamic>) {
      return CourseModel.fromJson(data);
    }
    throw Exception('Dữ liệu khóa học không hợp lệ');
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
    final body = <String, dynamic>{
      'code': code,
      'title': title,
      'language': language,
    };
    if (description != null) body['description'] = description;
    if (targetAudience != null) body['targetAudience'] = targetAudience;
    if (thumbnailUrl != null) body['thumbnailUrl'] = thumbnailUrl;

    final response = await apiClient.post(ApiEndpoints.courses, data: body);

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return CourseModel.fromJson(data);
    }
    throw Exception('Không thể tạo khóa học');
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
    final updateData = <String, dynamic>{};
    if (code != null) updateData['code'] = code;
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (targetAudience != null) updateData['targetAudience'] = targetAudience;
    if (language != null) updateData['language'] = language;
    if (thumbnailUrl != null) updateData['thumbnailUrl'] = thumbnailUrl;
    if (isActive != null) updateData['isActive'] = isActive;

    final response = await apiClient.patch(
      ApiEndpoints.courseDetail(id),
      data: updateData,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return CourseModel.fromJson(data);
    }
    return getCourseDetail(id);
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
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'order': order,
      'estimatedSessions': estimatedSessions,
      'tuitionFee': tuitionFee,
    };
    if (description != null) body['description'] = description;

    final response = await apiClient.post(
      ApiEndpoints.courseLevels(courseId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return CourseLevelModel.fromJson(data);
    }
    throw Exception('Không thể tạo cấp độ');
  }

  @override
  Future<CourseLevelModel> updateLevel(
    String levelId,
    Map<String, dynamic> changes,
  ) async {
    final response = await apiClient.patch('/levels/$levelId', data: changes);
    final data = response is Map<String, dynamic>
        ? response['data'] ?? response
        : response;
    if (data is Map<String, dynamic>) return CourseLevelModel.fromJson(data);
    throw const FormatException('Dữ liệu cấp độ sau khi lưu không hợp lệ');
  }

  @override
  Future<ModuleModel> createModule(
    String levelId, {
    required String title,
    int order = 1,
    String? description,
  }) async {
    final body = <String, dynamic>{'title': title, 'order': order};
    if (description != null) body['description'] = description;

    final response = await apiClient.post(
      ApiEndpoints.levelModules(levelId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return ModuleModel.fromJson(data);
    }
    throw Exception('Không thể tạo module');
  }

  @override
  Future<LessonModel> createLesson(
    String moduleId, {
    required String title,
    int order = 1,
    String? content,
    int durationMinutes = 90,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'order': order,
      'durationMinutes': durationMinutes,
    };
    if (content != null) body['content'] = content;

    final response = await apiClient.post(
      ApiEndpoints.moduleLessons(moduleId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return LessonModel.fromJson(data);
    }
    throw Exception('Không thể tạo bài học');
  }

  @override
  Future<LessonMaterialModel> createMaterial(
    String lessonId, {
    required String title,
    required String fileUrl,
    String fileType = 'DOCUMENT',
    int? fileSizeBytes,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
    };
    if (fileSizeBytes != null) body['fileSizeBytes'] = fileSizeBytes;

    final response = await apiClient.post(
      ApiEndpoints.lessonMaterials(lessonId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return LessonMaterialModel.fromJson(data);
    }
    throw Exception('Không thể thêm tài liệu');
  }
}
