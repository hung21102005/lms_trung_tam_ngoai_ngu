import 'dart:typed_data';

import '../../data/models/assignment_model.dart';

abstract class AssignmentsRepository {
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  );
  Future<List<AssignmentModel>> getClassAssignments(String classId);
  Future<AssignmentModel> createAssignment(
    String classId, {
    required String title,
    String? description,
    String? type,
    String? deadline,
    double? maxScore,
    List<Map<String, dynamic>>? attachments,
  });
  Future<AssignmentModel> getAssignmentDetail(String id);
  Future<AssignmentModel> updateAssignment(
    String id, {
    required String title,
    required String description,
    required String type,
    String? deadline,
    required double maxScore,
    required List<Map<String, dynamic>> attachments,
  });
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  });
  Future<SubmissionModel> saveDraft(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  });
  Future<SubmissionModel> publishResult(String submissionId);
  Future<SubmissionModel> returnSubmission(
    String submissionId,
    String feedback,
  );
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  );
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  });
}
