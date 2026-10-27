import 'package:equatable/equatable.dart';
import '../../data/models/class_model.dart';

abstract class ClassesState extends Equatable {
  const ClassesState();

  @override
  List<Object?> get props => [];
}

class ClassesInitial extends ClassesState {}

class ClassesLoading extends ClassesState {}

class ClassesLoaded extends ClassesState {
  final List<ClassModel> classes;
  final String selectedStatus;
  final String? selectedBranchId;
  final String searchQuery;

  const ClassesLoaded({
    required this.classes,
    this.selectedStatus = 'ALL',
    this.selectedBranchId,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [classes, selectedStatus, selectedBranchId, searchQuery];
}

class ClassDetailLoading extends ClassesState {}

class ClassDetailLoaded extends ClassesState {
  final ClassModel classDetail;

  const ClassDetailLoaded(this.classDetail);

  @override
  List<Object?> get props => [classDetail];
}

class MyClassesLoaded extends ClassesState {
  final List<ClassModel> classes;

  const MyClassesLoaded(this.classes);

  @override
  List<Object?> get props => [classes];
}

class MyScheduleLoading extends ClassesState {}

class MyScheduleLoaded extends ClassesState {
  final List<ClassSessionModel> sessions;
  final DateTime selectedDay;

  const MyScheduleLoaded({
    required this.sessions,
    required this.selectedDay,
  });

  @override
  List<Object?> get props => [sessions, selectedDay];
}

class ClassOperationSuccess extends ClassesState {
  final String message;
  final dynamic data;

  const ClassOperationSuccess(this.message, {this.data});

  @override
  List<Object?> get props => [message, data];
}

class ClassesError extends ClassesState {
  final String message;

  const ClassesError(this.message);

  @override
  List<Object?> get props => [message];
}
