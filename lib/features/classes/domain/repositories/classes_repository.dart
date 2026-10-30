import '../../data/models/class_model.dart';

abstract class ClassesRepository {
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  });

  Future<ClassModel> getClassDetail(String id);

  Future<ClassModel> createClass({
    required String code,
    required String name,
    required String courseId,
    required String levelId,
    required String branchId,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String status = 'PLANNING',
    required String startDate,
    required List<String> scheduleDays,
    required String startTime,
    required String endTime,
    int totalSessions = 24,
    int maxCapacity = 20,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  });

  Future<ClassModel> updateClass(
    String id, {
    String? code,
    String? name,
    String? roomId,
    String? mainTeacherId,
    String? assistantTeacherId,
    String? status,
    String? startDate,
    List<String>? scheduleDays,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    double? tuitionFee,
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  });

  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  });

  Future<void> removeStudent(String classId, String studentId);

  Future<void> deleteClass(String id);

  Future<List<ClassSessionModel>> getClassSessions(String classId);

  Future<ClassSessionModel> updateSession(
    String sessionId, {
    String? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? teacherId,
    String? status,
    String? notes,
  });

  Future<List<ClassModel>> getMyClasses();

  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  });
}

extension ClassesRepositoryExtension on ClassesRepository {
  Future<ClassSessionModel> updateSessionWithTitle(
    String sessionId, {
    String? title,
    String? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? teacherId,
    String? status,
    String? notes,
  }) {
    final dynamic self = this;
    try {
      return self.updateSession(
        sessionId,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        roomId: roomId,
        teacherId: teacherId,
        status: status,
        notes: notes,
      ) as Future<ClassSessionModel>;
    } catch (_) {
      return updateSession(
        sessionId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        roomId: roomId,
        teacherId: teacherId,
        status: status,
        notes: notes,
      );
    }
  }
}
