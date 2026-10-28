import 'package:equatable/equatable.dart';

abstract class ClassesEvent extends Equatable {
  const ClassesEvent();

  @override
  List<Object?> get props => [];
}

class FetchClasses extends ClassesEvent {
  final String? search;
  final String? status;
  final String? branchId;
  final String? courseId;
  final bool refresh;

  const FetchClasses({
    this.search,
    this.status,
    this.branchId,
    this.courseId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [search, status, branchId, courseId, refresh];
}

class FetchClassDetail extends ClassesEvent {
  final String id;

  const FetchClassDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchMyClasses extends ClassesEvent {
  const FetchMyClasses();
}

class FetchMySchedule extends ClassesEvent {
  final DateTime? fromDate;
  final DateTime? toDate;

  const FetchMySchedule({this.fromDate, this.toDate});

  @override
  List<Object?> get props => [fromDate, toDate];
}

class CreateClassEvent extends ClassesEvent {
  final String code;
  final String name;
  final String courseId;
  final String levelId;
  final String branchId;
  final String? roomId;
  final String? mainTeacherId;
  final String? assistantTeacherId;
  final String status;
  final String startDate;
  final List<String> scheduleDays;
  final String startTime;
  final String endTime;
  final int totalSessions;
  final int maxCapacity;
  final double? tuitionFee;
  final String? registrationOpenAt;
  final String? registrationCloseAt;
  final String? notes;

  const CreateClassEvent({
    required this.code,
    required this.name,
    required this.courseId,
    required this.levelId,
    required this.branchId,
    this.roomId,
    this.mainTeacherId,
    this.assistantTeacherId,
    this.status = 'PLANNING',
    required this.startDate,
    required this.scheduleDays,
    required this.startTime,
    required this.endTime,
    this.totalSessions = 24,
    this.maxCapacity = 20,
    this.tuitionFee,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
    code,
    name,
    courseId,
    levelId,
    branchId,
    roomId,
    mainTeacherId,
    assistantTeacherId,
    status,
    startDate,
    scheduleDays,
    startTime,
    endTime,
    totalSessions,
    maxCapacity,
    tuitionFee,
    registrationOpenAt,
    registrationCloseAt,
    notes,
  ];
}

class EnrollStudentEvent extends ClassesEvent {
  final String classId;
  final String studentId;
  final double tuitionPaid;
  final String? notes;

  const EnrollStudentEvent({
    required this.classId,
    required this.studentId,
    this.tuitionPaid = 0,
    this.notes,
  });

  @override
  List<Object?> get props => [classId, studentId, tuitionPaid, notes];
}

class RemoveStudentEvent extends ClassesEvent {
  final String classId;
  final String studentId;

  const RemoveStudentEvent({required this.classId, required this.studentId});

  @override
  List<Object?> get props => [classId, studentId];
}

class UpdateSessionEvent extends ClassesEvent {
  final String sessionId;
  final String classId;
  final String? title;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? roomId;
  final String? teacherId;
  final String? status;
  final String? notes;

  const UpdateSessionEvent({
    required this.sessionId,
    required this.classId,
    this.title,
    this.date,
    this.startTime,
    this.endTime,
    this.roomId,
    this.teacherId,
    this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [
    sessionId,
    classId,
    title,
    date,
    startTime,
    endTime,
    roomId,
    teacherId,
    status,
    notes,
  ];
}
