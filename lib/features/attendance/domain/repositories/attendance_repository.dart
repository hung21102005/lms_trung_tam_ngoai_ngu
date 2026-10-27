import '../../data/models/attendance_model.dart';

abstract class AttendanceRepository {
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
