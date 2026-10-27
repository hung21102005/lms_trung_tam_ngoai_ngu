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

  const FetchCourses({
    this.search,
    this.language,
    this.refresh = false,
  });

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
  List<Object?> get props => [code, title, description, targetAudience, language];
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
