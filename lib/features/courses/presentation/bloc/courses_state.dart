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

class CourseDetailLoading extends CoursesState {}

class CourseDetailLoaded extends CoursesState {
  final CourseModel course;

  const CourseDetailLoaded(this.course);

  @override
  List<Object?> get props => [course];
}

class CourseOperationSuccess extends CoursesState {
  final String message;
  final dynamic data;

  const CourseOperationSuccess(this.message, {this.data});

  @override
  List<Object?> get props => [message, data];
}

class CoursesError extends CoursesState {
  final String message;

  const CoursesError(this.message);

  @override
  List<Object?> get props => [message];
}
