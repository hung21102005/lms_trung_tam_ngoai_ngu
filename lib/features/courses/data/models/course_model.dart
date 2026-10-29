import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String code;
  final String title;
  final String? description;
  final String? publicDescription;
  final String? targetAudience;
  final String language;
  final String? thumbnailUrl;
  final bool isActive;
  final String publicationStatus;
  final String curriculumVersion;
  final int levelsCount;
  final int classesCount;
  final List<CourseLevelModel> levels;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseModel({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    this.publicDescription,
    this.targetAudience,
    this.language = 'English',
    this.thumbnailUrl,
    this.isActive = true,
    this.publicationStatus = 'DRAFT',
    this.curriculumVersion = '1.0',
    this.levelsCount = 0,
    this.classesCount = 0,
    this.levels = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    var rawLevels = json['levels'];
    List<CourseLevelModel> parsedLevels = [];
    if (rawLevels is List) {
      parsedLevels = rawLevels
          .map(
            (item) => CourseLevelModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    final counts = json['_count'] as Map<String, dynamic>?;
    final lCount = counts?['levels'] as int? ?? parsedLevels.length;
    final cCount = counts?['classes'] as int? ?? 0;

    return CourseModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      publicDescription: json['publicDescription'] as String?,
      targetAudience: json['targetAudience'] as String?,
      language: json['language'] as String? ?? 'English',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      publicationStatus: json['publicationStatus'] as String? ?? 'DRAFT',
      curriculumVersion: json['curriculumVersion'] as String? ?? '1.0',
      levelsCount: lCount,
      classesCount: cCount,
      levels: parsedLevels,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'publicDescription': publicDescription,
      'targetAudience': targetAudience,
      'language': language,
      'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
      'publicationStatus': publicationStatus,
      'curriculumVersion': curriculumVersion,
    };
  }

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    description,
    publicDescription,
    targetAudience,
    language,
    thumbnailUrl,
    isActive,
    publicationStatus,
    curriculumVersion,
    levelsCount,
    classesCount,
    levels,
  ];
}

class CourseLevelModel extends Equatable {
  final String id;
  final String courseId;
  final String code;
  final String name;
  final String? description;
  final int order;
  final int estimatedSessions;
  final double tuitionFee;
  final String? cefrLevel;
  final double? ieltsTargetBand;
  final int? toeicTargetScore;
  final String? cambridgeQualification;
  final String? entryRequirements;
  final Map<String, dynamic>? expectedOutcomes;
  final Map<String, dynamic>? assessmentScheme;
  final String? completionCriteria;
  final int? recommendedHours;
  final List<ModuleModel> modules;
  final int classesCount;

  const CourseLevelModel({
    required this.id,
    required this.courseId,
    required this.code,
    required this.name,
    this.description,
    this.order = 1,
    this.estimatedSessions = 24,
    this.tuitionFee = 0,
    this.cefrLevel,
    this.ieltsTargetBand,
    this.toeicTargetScore,
    this.cambridgeQualification,
    this.entryRequirements,
    this.expectedOutcomes,
    this.assessmentScheme,
    this.completionCriteria,
    this.recommendedHours,
    this.modules = const [],
    this.classesCount = 0,
  });

  factory CourseLevelModel.fromJson(Map<String, dynamic> json) {
    var rawModules = json['modules'];
    List<ModuleModel> parsedModules = [];
    if (rawModules is List) {
      parsedModules = rawModules
          .map((item) => ModuleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final counts = json['_count'] as Map<String, dynamic>?;
    final cCount = counts?['classes'] as int? ?? 0;

    return CourseLevelModel(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      order: json['order'] as int? ?? 1,
      estimatedSessions: json['estimatedSessions'] as int? ?? 24,
      tuitionFee: (json['tuitionFee'] != null)
          ? double.tryParse(json['tuitionFee'].toString()) ?? 0.0
          : 0.0,
      cefrLevel: json['cefrLevel'] as String?,
      ieltsTargetBand: double.tryParse(
        json['ieltsTargetBand']?.toString() ?? '',
      ),
      toeicTargetScore: int.tryParse(
        json['toeicTargetScore']?.toString() ?? '',
      ),
      cambridgeQualification: json['cambridgeQualification'] as String?,
      entryRequirements: json['entryRequirements'] as String?,
      expectedOutcomes: json['expectedOutcomes'] is Map
          ? Map<String, dynamic>.from(json['expectedOutcomes'] as Map)
          : null,
      assessmentScheme: json['assessmentScheme'] is Map
          ? Map<String, dynamic>.from(json['assessmentScheme'] as Map)
          : null,
      completionCriteria: json['completionCriteria'] as String?,
      recommendedHours: int.tryParse(
        json['recommendedHours']?.toString() ?? '',
      ),
      modules: parsedModules,
      classesCount: cCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'code': code,
      'name': name,
      'description': description,
      'order': order,
      'estimatedSessions': estimatedSessions,
      'tuitionFee': tuitionFee,
      'cefrLevel': cefrLevel,
      'ieltsTargetBand': ieltsTargetBand,
      'toeicTargetScore': toeicTargetScore,
      'cambridgeQualification': cambridgeQualification,
      'entryRequirements': entryRequirements,
      'expectedOutcomes': expectedOutcomes,
      'assessmentScheme': assessmentScheme,
      'completionCriteria': completionCriteria,
      'recommendedHours': recommendedHours,
    };
  }

  @override
  List<Object?> get props => [
    id,
    courseId,
    code,
    name,
    description,
    order,
    estimatedSessions,
    tuitionFee,
    cefrLevel,
    ieltsTargetBand,
    toeicTargetScore,
    cambridgeQualification,
    entryRequirements,
    expectedOutcomes,
    assessmentScheme,
    completionCriteria,
    recommendedHours,
    modules,
    classesCount,
  ];
}

class ModuleModel extends Equatable {
  final String id;
  final String levelId;
  final String title;
  final int order;
  final String? description;
  final List<LessonModel> lessons;

  const ModuleModel({
    required this.id,
    required this.levelId,
    required this.title,
    this.order = 1,
    this.description,
    this.lessons = const [],
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    var rawLessons = json['lessons'];
    List<LessonModel> parsedLessons = [];
    if (rawLessons is List) {
      parsedLessons = rawLessons
          .map((item) => LessonModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ModuleModel(
      id: json['id'] as String? ?? '',
      levelId: json['levelId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 1,
      description: json['description'] as String?,
      lessons: parsedLessons,
    );
  }

  @override
  List<Object?> get props => [id, levelId, title, order, description, lessons];
}

class LessonModel extends Equatable {
  final String id;
  final String moduleId;
  final String title;
  final int order;
  final String? content;
  final int durationMinutes;
  final List<LessonMaterialModel> materials;

  const LessonModel({
    required this.id,
    required this.moduleId,
    required this.title,
    this.order = 1,
    this.content,
    this.durationMinutes = 90,
    this.materials = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    var rawMaterials = json['materials'];
    List<LessonMaterialModel> parsedMaterials = [];
    if (rawMaterials is List) {
      parsedMaterials = rawMaterials
          .map(
            (item) =>
                LessonMaterialModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return LessonModel(
      id: json['id'] as String? ?? '',
      moduleId: json['moduleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 1,
      content: json['content'] as String?,
      durationMinutes: json['durationMinutes'] as int? ?? 90,
      materials: parsedMaterials,
    );
  }

  @override
  List<Object?> get props => [
    id,
    moduleId,
    title,
    order,
    content,
    durationMinutes,
    materials,
  ];
}

class LessonMaterialModel extends Equatable {
  final String id;
  final String lessonId;
  final String title;
  final String fileUrl;
  final String fileType; // DOCUMENT, AUDIO, VIDEO, IMAGE, OTHER
  final int? fileSizeBytes;
  final int order;

  const LessonMaterialModel({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.fileUrl,
    this.fileType = 'DOCUMENT',
    this.fileSizeBytes,
    this.order = 1,
  });

  factory LessonMaterialModel.fromJson(Map<String, dynamic> json) {
    return LessonMaterialModel(
      id: json['id'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'DOCUMENT',
      fileSizeBytes: json['fileSizeBytes'] as int?,
      order: json['order'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [
    id,
    lessonId,
    title,
    fileUrl,
    fileType,
    fileSizeBytes,
    order,
  ];
}
