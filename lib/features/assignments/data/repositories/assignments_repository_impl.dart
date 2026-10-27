import 'dart:typed_data';

import '../../domain/repositories/assignments_repository.dart';
import '../datasources/assignments_remote_datasource.dart';
import '../models/assignment_model.dart';

class AssignmentsRepositoryImpl implements AssignmentsRepository {
  final AssignmentsRemoteDataSource remoteDataSource;

  AssignmentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) => remoteDataSource.uploadAttachment(fileName, bytes);

  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) {
    return remoteDataSource.getClassAssignments(classId);
  }

  @override
  Future<AssignmentModel> createAssignment(
    String classId, {
    required String title,
    String? description,
    String? type,
    String? deadline,
    double? maxScore,
    List<Map<String, dynamic>>? attachments,
  }) {
    return remoteDataSource.createAssignment(
      classId,
      title: title,
      description: description,
      type: type,
      deadline: deadline,
      maxScore: maxScore,
      attachments: attachments,
    );
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) {
    return remoteDataSource.getAssignmentDetail(id);
  }

  @override
  Future<AssignmentModel> updateAssignment(
    String id, {
    required String title,
    required String description,
    required String type,
    String? deadline,
    required double maxScore,
    required List<Map<String, dynamic>> attachments,
  }) => remoteDataSource.updateAssignment(
    id,
    title: title,
    description: description,
    type: type,
    deadline: deadline,
    maxScore: maxScore,
    attachments: attachments,
  );

  @override
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) {
    return remoteDataSource.submitAssignment(
      assignmentId,
      content: content,
      fileUrls: fileUrls,
    );
  }

  @override
  Future<SubmissionModel> saveDraft(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) => remoteDataSource.saveDraft(
    assignmentId,
    content: content,
    fileUrls: fileUrls,
  );

  @override
  Future<SubmissionModel> publishResult(String submissionId) =>
      remoteDataSource.publishResult(submissionId);

  @override
  Future<SubmissionModel> returnSubmission(
    String submissionId,
    String feedback,
  ) => remoteDataSource.returnSubmission(submissionId, feedback);

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) {
    return remoteDataSource.getAssignmentSubmissions(assignmentId);
  }

  @override
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  }) {
    return remoteDataSource.gradeSubmission(
      submissionId,
      score: score,
      feedback: feedback,
    );
  }
}
