import '../../domain/repositories/classes_repository.dart';
import '../datasources/classes_remote_datasource.dart';
import '../models/class_model.dart';

class ClassesRepositoryImpl implements ClassesRepository {
  final ClassesRemoteDataSource remoteDataSource;

  ClassesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) {
    return remoteDataSource.getClasses(
      search: search,
      status: status,
      branchId: branchId,
      courseId: courseId,
      teacherId: teacherId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ClassModel> getClassDetail(String id) {
    return remoteDataSource.getClassDetail(id);
  }

  @override
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
  }) {
    return remoteDataSource.createClass(
      code: code,
      name: name,
      courseId: courseId,
      levelId: levelId,
      branchId: branchId,
      roomId: roomId,
      mainTeacherId: mainTeacherId,
      assistantTeacherId: assistantTeacherId,
      status: status,
      startDate: startDate,
      scheduleDays: scheduleDays,
      startTime: startTime,
      endTime: endTime,
      totalSessions: totalSessions,
      maxCapacity: maxCapacity,
      tuitionFee: tuitionFee,
      registrationOpenAt: registrationOpenAt,
      registrationCloseAt: registrationCloseAt,
      notes: notes,
    );
  }

  @override
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
    String? notes,
  }) {
    return remoteDataSource.updateClass(
      id,
      code: code,
      name: name,
      roomId: roomId,
      mainTeacherId: mainTeacherId,
      assistantTeacherId: assistantTeacherId,
      status: status,
      startDate: startDate,
      scheduleDays: scheduleDays,
      startTime: startTime,
      endTime: endTime,
      maxCapacity: maxCapacity,
      tuitionFee: tuitionFee,
      notes: notes,
    );
  }

  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) {
    return remoteDataSource.enrollStudent(
      classId,
      studentId: studentId,
      tuitionPaid: tuitionPaid,
      notes: notes,
    );
  }

  @override
  Future<void> removeStudent(String classId, String studentId) {
    return remoteDataSource.removeStudent(classId, studentId);
  }

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) {
    return remoteDataSource.getClassSessions(classId);
  }

  @override
  Future<ClassSessionModel> updateSession(
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
    return remoteDataSource.updateSession(
      sessionId,
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      roomId: roomId,
      teacherId: teacherId,
      status: status,
      notes: notes,
    );
  }

  @override
  Future<List<ClassModel>> getMyClasses() {
    return remoteDataSource.getMyClasses();
  }

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) {
    return remoteDataSource.getMySchedule(fromDate: fromDate, toDate: toDate);
  }
}
