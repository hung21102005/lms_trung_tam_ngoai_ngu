import '../../../../core/network/api_client.dart';

class TrainingProgramRecord {
  final String id;
  final String code;
  final String slug;
  final String nameVi;
  final String nameEn;
  final String category;
  final String description;
  final String targetAudience;
  final String status;
  final bool isPublic;
  final int courseCount;
  final List<ProgramCourseRecord> courses;

  const TrainingProgramRecord({
    required this.id,
    required this.code,
    required this.slug,
    required this.nameVi,
    required this.nameEn,
    required this.category,
    required this.description,
    required this.targetAudience,
    required this.status,
    required this.isPublic,
    required this.courseCount,
    this.courses = const [],
  });

  factory TrainingProgramRecord.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    final rawCourses = json['courses'];
    return TrainingProgramRecord(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      nameVi: json['nameVi'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetAudience: json['targetAudience'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      isPublic: json['isPublic'] as bool? ?? false,
      courseCount: count is Map
          ? (count['courses'] as num?)?.toInt() ?? 0
          : rawCourses is List
          ? rawCourses.length
          : 0,
      courses: rawCourses is List
          ? rawCourses
                .map(
                  (value) => ProgramCourseRecord.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class ProgramCourseRecord {
  final String id;
  final String code;
  final String title;
  final String status;
  final bool isActive;
  final String? programId;
  final String slug;
  final String description;
  final String publicDescription;

  const ProgramCourseRecord({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.isActive,
    this.programId,
    this.slug = '',
    this.description = '',
    this.publicDescription = '',
  });

  factory ProgramCourseRecord.fromJson(Map<String, dynamic> json) =>
      ProgramCourseRecord(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['publicationStatus'] as String? ?? 'DRAFT',
        isActive: json['isActive'] as bool? ?? false,
        programId: json['programId'] as String?,
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String? ?? '',
        publicDescription: json['publicDescription'] as String? ?? '',
      );
}

class ProgramCatalogRepository {
  final ApiClient apiClient;

  const ProgramCatalogRepository(this.apiClient);

  dynamic _unwrap(dynamic response) => response is Map<String, dynamic>
      ? response['data'] ?? response
      : response;

  Future<List<TrainingProgramRecord>> getPrograms() async {
    final data = _unwrap(await apiClient.get('/programs'));
    if (data is! List) {
      throw const FormatException('Danh sách chương trình không hợp lệ');
    }
    return data
        .map(
          (item) => TrainingProgramRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<TrainingProgramRecord> getProgram(String id) async {
    final data = _unwrap(await apiClient.get('/programs/$id'));
    if (data is! Map) {
      throw const FormatException('Chi tiết chương trình không hợp lệ');
    }
    return TrainingProgramRecord.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveProgram({
    String? id,
    required String code,
    required String slug,
    required String nameVi,
    required String nameEn,
    required String category,
    required String description,
    required String targetAudience,
  }) async {
    final data = {
      'code': code,
      'slug': slug,
      'nameVi': nameVi,
      'nameEn': nameEn,
      'category': category,
      'description': description,
      'targetAudience': targetAudience,
    };
    if (id == null) {
      await apiClient.post('/programs', data: data);
    } else {
      await apiClient.patch('/programs/$id', data: data);
    }
  }

  Future<void> changeStatus(String id, String status) async {
    await apiClient.patch('/programs/$id/status', data: {'status': status});
  }

  Future<void> setVisibility(String id, bool isPublic) async {
    await apiClient.patch(
      '/programs/$id/visibility',
      data: {'isPublic': isPublic},
    );
  }

  Future<void> changeCourseStatus(String id, String status) async {
    await apiClient.patch('/courses/$id/publication', data: {'status': status});
  }

  Future<List<ProgramCourseRecord>> searchUnassignedCourses(
    String search,
  ) async {
    final data = _unwrap(
      await apiClient.get(
        '/courses',
        queryParameters: {'search': search, 'page': 1, 'limit': 50},
      ),
    );
    if (data is! Map || data['items'] is! List) {
      throw const FormatException('Danh sách khóa học không hợp lệ');
    }
    return (data['items'] as List)
        .map(
          (item) => ProgramCourseRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((course) => course.programId == null)
        .toList();
  }

  Future<void> attachCourse(String courseId, String programId) async {
    await apiClient.patch('/courses/$courseId', data: {'programId': programId});
  }

  Future<void> saveCourse({
    String? id,
    required String programId,
    required String code,
    required String title,
    required String slug,
    required String description,
    required String publicDescription,
    required bool isActive,
  }) async {
    final data = <String, dynamic>{
      'programId': programId,
      'slug': slug,
      'description': description,
      'publicDescription': publicDescription,
      'isActive': isActive,
    };
    if (id == null) {
      data['code'] = code;
      data['title'] = title;
      await apiClient.post('/courses', data: data);
    } else {
      data['code'] = code;
      data['title'] = title;
      await apiClient.patch('/courses/$id', data: data);
    }
  }
}
