import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/assignment_model.dart';

abstract class AssignmentsRemoteDataSource {
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

class AssignmentsRemoteDataSourceImpl implements AssignmentsRemoteDataSource {
  final ApiClient apiClient;

  AssignmentsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) async {
    final file = MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: MultipartFile.lookupMediaType(fileName),
    );
    final response = await apiClient.post(
      ApiEndpoints.uploadFile,
      data: FormData.fromMap({'file': file, 'folder': 'assignments'}),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    final payload = response is Map<String, dynamic>
        ? response['data'] ?? response
        : response;
    final data = payload as Map<String, dynamic>;
    return AssignmentAttachmentModel.fromJson({
      'name': data['originalName'] ?? fileName,
      'url': data['url'],
      'fileType': (data['mimetype'] as String?)?.startsWith('image/') == true
          ? 'IMAGE'
          : 'DOCUMENT',
      'size': data['size'],
    });
  }

  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async {
    String targetClassId = classId.trim();

    if (targetClassId.isEmpty) {
      final myClassesResp = await apiClient.get(ApiEndpoints.myClasses);
      final myData = myClassesResp is Map<String, dynamic>
          ? (myClassesResp['data'] ?? myClassesResp)
          : myClassesResp;
      final myList = myData is List
          ? myData
          : (myData is Map<String, dynamic> && myData['items'] is List
                ? myData['items'] as List
                : []);
      if (myList.isNotEmpty && myList.first is Map<String, dynamic>) {
        targetClassId =
            (myList.first as Map<String, dynamic>)['id']?.toString() ?? '';
      }
    }

    if (targetClassId.isEmpty) return [];

    final response = await apiClient.get(
      ApiEndpoints.classAssignments(targetClassId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List
              ? data['items'] as List
              : []);
    final parsed = list
        .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return parsed;
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
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.classAssignments(classId),
      data: {
        'title': title,
        'description': ?description,
        'type': ?type,
        'deadline': ?deadline,
        'maxScore': ?maxScore,
        'attachments': ?attachments,
      },
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return AssignmentModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.assignmentDetail(id));
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    final map = data as Map<String, dynamic>;
    final assignmentMap =
        map['assignment'] as Map<String, dynamic>? ??
        (map.containsKey('title') ? map : {});
    final stats = map['stats'] as Map<String, dynamic>?;
    final mySub = map['mySubmission'] as Map<String, dynamic>?;

    final merged = Map<String, dynamic>.from(assignmentMap);
    if (stats != null) merged['stats'] = stats;
    if (mySub != null) merged['mySubmission'] = mySub;

    return AssignmentModel.fromJson(merged);
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
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.assignmentDetail(id),
      data: {
        'title': title,
        'description': description,
        'type': type,
        'deadline': deadline,
        'maxScore': maxScore,
        'attachments': attachments,
      },
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return AssignmentModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.submitAssignment(assignmentId),
      data: {'content': ?content, 'fileUrls': ?fileUrls},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SubmissionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SubmissionModel> saveDraft(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.saveAssignmentDraft(assignmentId),
      data: {'content': ?content, 'fileUrls': ?fileUrls},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SubmissionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SubmissionModel> publishResult(String submissionId) async {
    final response = await apiClient.patch(
      ApiEndpoints.publishSubmissionResult(submissionId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SubmissionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<SubmissionModel> returnSubmission(
    String submissionId,
    String feedback,
  ) async {
    final response = await apiClient.patch(
      ApiEndpoints.returnSubmission(submissionId),
      data: {'feedback': feedback},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SubmissionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.assignmentSubmissions(assignmentId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return AssignmentSubmissionsResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  @override
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.gradeSubmission(submissionId),
      data: {'score': score, 'feedback': ?feedback},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SubmissionModel.fromJson(data as Map<String, dynamic>);
  }
}
