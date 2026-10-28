import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

class FetchCourses extends CoursesEvent {
  final String? search;
  final String? language;
  final bool refresh;

  const FetchCourses({this.search, this.language, this.refresh = false});

  @override
  List<Object?> get props => [search, language, refresh];
}

class FetchCourseDetail extends CoursesEvent {
  final String id;

  const FetchCourseDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateCourseEvent extends CoursesEvent {
  final String code;
  final String title;
  final String? description;
  final String? targetAudience;
  final String language;

  const CreateCourseEvent({
    required this.code,
    required this.title,
    this.description,
    this.targetAudience,
    this.language = 'English',
  });

  @override
  List<Object?> get props => [
    code,
    title,
    description,
    targetAudience,
    language,
  ];
}

class CreateCourseLevelEvent extends CoursesEvent {
  final String courseId;
  final String code;
  final String name;
  final String? description;
  final int order;
  final int estimatedSessions;
  final double tuitionFee;

  const CreateCourseLevelEvent({
    required this.courseId,
    required this.code,
    required this.name,
    this.description,
    this.order = 1,
    this.estimatedSessions = 24,
    this.tuitionFee = 0,
  });

  @override
  List<Object?> get props => [
    courseId,
    code,
    name,
    description,
    order,
    estimatedSessions,
    tuitionFee,
  ];
}

class UpdateCourseLevelEvent extends CoursesEvent {
  final String courseId;
  final String levelId;
  final Map<String, dynamic> changes;

  const UpdateCourseLevelEvent({
    required this.courseId,
    required this.levelId,
    required this.changes,
  });

  @override
  List<Object?> get props => [courseId, levelId, changes];
}

class UpdateModuleEvent extends CoursesEvent {
  final String courseId;
  final String moduleId;
  final Map<String, dynamic> changes;

  const UpdateModuleEvent({
    required this.courseId,
    required this.moduleId,
    required this.changes,
  });

  @override
  List<Object?> get props => [courseId, moduleId, changes];
}

class UpdateLessonEvent extends CoursesEvent {
  final String courseId;
  final String lessonId;
  final Map<String, dynamic> changes;

  const UpdateLessonEvent({
    required this.courseId,
    required this.lessonId,
    required this.changes,
  });

  @override
  List<Object?> get props => [courseId, lessonId, changes];
}

class CreateModuleEvent extends CoursesEvent {
  final String courseId;
  final String levelId;
  final Map<String, dynamic> values;

  const CreateModuleEvent({
    required this.courseId,
    required this.levelId,
    required this.values,
  });

  @override
  List<Object?> get props => [courseId, levelId, values];
}

class CreateLessonEvent extends CoursesEvent {
  final String courseId;
  final String moduleId;
  final Map<String, dynamic> values;

  const CreateLessonEvent({
    required this.courseId,
    required this.moduleId,
    required this.values,
  });

  @override
  List<Object?> get props => [courseId, moduleId, values];
}

class UploadLessonMaterialEvent extends CoursesEvent {
  final String courseId;
  final String lessonId;
  final String title;
  final String fileName;
  final Uint8List bytes;

  const UploadLessonMaterialEvent({
    required this.courseId,
    required this.lessonId,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  @override
  List<Object?> get props => [courseId, lessonId, title, fileName, bytes];
}
