import 'package:equatable/equatable.dart';
import '../../data/models/course_model.dart';

abstract class CoursesState extends Equatable {
  const CoursesState();

  @override
  List<Object?> get props => [];
}

class CoursesInitial extends CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesLoaded extends CoursesState {
  final List<CourseModel> courses;
  final String selectedLanguage;
  final String searchQuery;

  const CoursesLoaded({
    required this.courses,
    this.selectedLanguage = 'All',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [courses, selectedLanguage, searchQuery];
}

class CourseMutationFailure extends CoursesLoaded {
  final String message;

  const CourseMutationFailure({
    required this.message,
    required super.courses,
    required super.selectedLanguage,
    required super.searchQuery,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

class CourseDetailLoading extends CoursesState {}

class CourseDetailLoaded extends CoursesState {
  final CourseModel course;

  const CourseDetailLoaded(this.course);

  @override
  List<Object?> get props => [course];
}

class CoursePublicationCheckLoaded extends CoursesState {
  final String courseId;
  final Map<String, dynamic> checkResult;

  const CoursePublicationCheckLoaded({
    required this.courseId,
    required this.checkResult,
  });

  @override
  List<Object?> get props => [courseId, checkResult];
}

class CourseOperationSuccess extends CoursesState {
  final String message;
  final dynamic data;
  final CourseModel? course;

  const CourseOperationSuccess(this.message, {this.data, this.course});

  @override
  List<Object?> get props => [message, data, course];
}

class CoursesError extends CoursesState {
  final String message;

  const CoursesError(this.message);

  @override
  List<Object?> get props => [message];
}
