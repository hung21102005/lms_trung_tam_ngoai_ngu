import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) {
    return remoteDataSource.getSessionAttendance(sessionId);
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) {
    return remoteDataSource.batchMarkAttendance(
      sessionId,
      students,
      lock: lock,
    );
  }

  @override
  Future<void> updateAttendance(String id, {String? status, String? notes}) {
    return remoteDataSource.updateAttendance(id, status: status, notes: notes);
  }

  @override
  Future<StudentAttendanceHistoryResponseModel> getStudentAttendance(
    String studentId,
  ) {
    return remoteDataSource.getStudentAttendance(studentId);
  }

  @override
  Future<Map<String, dynamic>> getClassAttendanceSummary(String classId) {
    return remoteDataSource.getClassAttendanceSummary(classId);
  }

  @override
  Future<MakeupRequestModel> createMakeupRequest({
    required String originalSessionId,
    String? targetSessionId,
    String? reason,
  }) {
    return remoteDataSource.createMakeupRequest(
      originalSessionId: originalSessionId,
      targetSessionId: targetSessionId,
      reason: reason,
    );
  }

  @override
  Future<List<MakeupRequestModel>> getMakeupRequests({
    String? status,
    String? studentId,
  }) {
    return remoteDataSource.getMakeupRequests(
      status: status,
      studentId: studentId,
    );
  }

  @override
  Future<MakeupRequestModel> updateMakeupRequest(
    String id, {
    required String status,
    String? reason,
  }) {
    return remoteDataSource.updateMakeupRequest(
      id,
      status: status,
      reason: reason,
    );
  }
}
