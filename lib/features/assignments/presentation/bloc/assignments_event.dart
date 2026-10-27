import 'package:equatable/equatable.dart';

abstract class AssignmentsEvent extends Equatable {
  const AssignmentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadClassAssignmentsEvent extends AssignmentsEvent {
  final String classId;

  const LoadClassAssignmentsEvent(this.classId);

  @override
  List<Object?> get props => [classId];
}

class LoadAssignmentDetailEvent extends AssignmentsEvent {
  final String assignmentId;

  const LoadAssignmentDetailEvent(this.assignmentId);

  @override
  List<Object?> get props => [assignmentId];
}

class CreateAssignmentEvent extends AssignmentsEvent {
  final String classId;
  final String title;
  final String? description;
  final String? type;
  final String? deadline;
  final double? maxScore;
  final List<Map<String, dynamic>>? attachments;

  const CreateAssignmentEvent({
    required this.classId,
    required this.title,
    this.description,
    this.type,
    this.deadline,
    this.maxScore,
    this.attachments,
  });

  @override
  List<Object?> get props => [
    classId,
    title,
    description,
    type,
    deadline,
    maxScore,
    attachments,
  ];
}

class SubmitAssignmentEvent extends AssignmentsEvent {
  final String assignmentId;
  final String? content;
  final List<Map<String, dynamic>>? fileUrls;

  const SubmitAssignmentEvent({
    required this.assignmentId,
    this.content,
    this.fileUrls,
  });

  @override
  List<Object?> get props => [assignmentId, content, fileUrls];
}

class LoadAssignmentSubmissionsEvent extends AssignmentsEvent {
  final String assignmentId;

  const LoadAssignmentSubmissionsEvent(this.assignmentId);

  @override
  List<Object?> get props => [assignmentId];
}

class GradeSubmissionEvent extends AssignmentsEvent {
  final String assignmentId;
  final String submissionId;
  final double score;
  final String? feedback;

  const GradeSubmissionEvent({
    required this.assignmentId,
    required this.submissionId,
    required this.score,
    this.feedback,
  });

  @override
  List<Object?> get props => [assignmentId, submissionId, score, feedback];
}
