import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionAttendanceEvent extends AttendanceEvent {
  final String sessionId;

  const LoadSessionAttendanceEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class BatchMarkAttendanceEvent extends AttendanceEvent {
  final String sessionId;
  final List<Map<String, dynamic>> students;

  const BatchMarkAttendanceEvent({
    required this.sessionId,
    required this.students,
  });

  @override
  List<Object?> get props => [sessionId, students];
}

class UpdateStudentStatusEvent extends AttendanceEvent {
  final String studentId;
  final String status;
  final String? notes;

  const UpdateStudentStatusEvent({
    required this.studentId,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [studentId, status, notes];
}

class LoadStudentAttendanceEvent extends AttendanceEvent {
  final String studentId;

  const LoadStudentAttendanceEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

class LoadClassAttendanceSummaryEvent extends AttendanceEvent {
  final String classId;

  const LoadClassAttendanceSummaryEvent(this.classId);

  @override
  List<Object?> get props => [classId];
}

class LoadMakeupRequestsEvent extends AttendanceEvent {
  final String? status;
  final String? studentId;

  const LoadMakeupRequestsEvent({this.status, this.studentId});

  @override
  List<Object?> get props => [status, studentId];
}

class CreateMakeupRequestEvent extends AttendanceEvent {
  final String originalSessionId;
  final String? targetSessionId;
  final String? reason;

  const CreateMakeupRequestEvent({
    required this.originalSessionId,
    this.targetSessionId,
    this.reason,
  });

  @override
  List<Object?> get props => [originalSessionId, targetSessionId, reason];
}

class UpdateMakeupRequestStatusEvent extends AttendanceEvent {
  final String id;
  final String status;
  final String? reason;

  const UpdateMakeupRequestStatusEvent({
    required this.id,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [id, status, reason];
}
