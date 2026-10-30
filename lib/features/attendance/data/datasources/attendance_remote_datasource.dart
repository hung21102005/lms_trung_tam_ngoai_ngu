import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<SessionAttendanceResponseModel> getSessionAttendance(String sessionId);
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  });
  Future<void> updateAttendance(String id, {String? status, String? notes});
  Future<StudentAttendanceHistoryResponseModel> getStudentAttendance(
    String studentId,
  );
  Future<Map<String, dynamic>> getClassAttendanceSummary(String classId);
  Future<MakeupRequestModel> createMakeupRequest({
    required String originalSessionId,
    String? targetSessionId,
    String? reason,
  });
  Future<List<MakeupRequestModel>> getMakeupRequests({
    String? status,
    String? studentId,
  });
  Future<MakeupRequestModel> updateMakeupRequest(
    String id, {
    required String status,
    String? reason,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.sessionAttendance(sessionId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SessionAttendanceResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.sessionAttendance(sessionId),
      data: {'students': students, 'lock': lock},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return SessionAttendanceResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> updateAttendance(
    String id, {
    String? status,
    String? notes,
  }) async {
    await apiClient.patch(
      ApiEndpoints.updateAttendance(id),
      data: {'status': ?status, 'notes': ?notes},
    );
  }

  @override
  Future<StudentAttendanceHistoryResponseModel> getStudentAttendance(
    String studentId,
  ) async {
    final response = await apiClient.get(
      ApiEndpoints.studentAttendance(studentId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return StudentAttendanceHistoryResponseModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> getClassAttendanceSummary(String classId) async {
    final response = await apiClient.get(
      ApiEndpoints.classAttendanceSummary(classId),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return data as Map<String, dynamic>;
  }

  @override
  Future<MakeupRequestModel> createMakeupRequest({
    required String originalSessionId,
    String? targetSessionId,
    String? reason,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.makeupRequests,
      data: {
        'originalSessionId': originalSessionId,
        'targetSessionId': ?targetSessionId,
        'reason': ?reason,
      },
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return MakeupRequestModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<MakeupRequestModel>> getMakeupRequests({
    String? status,
    String? studentId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (studentId != null) queryParams['studentId'] = studentId;

    final response = await apiClient.get(
      ApiEndpoints.makeupRequests,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List
              ? data['items'] as List
              : []);
    return list
        .map((e) => MakeupRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MakeupRequestModel> updateMakeupRequest(
    String id, {
    required String status,
    String? reason,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.makeupRequestDetail(id),
      data: {'status': status, 'reason': ?reason},
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return MakeupRequestModel.fromJson(data as Map<String, dynamic>);
  }
}
