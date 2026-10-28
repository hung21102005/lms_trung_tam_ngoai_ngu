import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/class_model.dart';

abstract class ClassesRemoteDataSource {
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
    String? notes,
  });

  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  });

  Future<void> removeStudent(String classId, String studentId);

  Future<List<ClassSessionModel>> getClassSessions(String classId);

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
  });

  Future<List<ClassModel>> getMyClasses();

  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  });
}

class ClassesRemoteDataSourceImpl implements ClassesRemoteDataSource {
  final ApiClient apiClient;

  ClassesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (branchId != null && branchId.isNotEmpty) {
      queryParams['branchId'] = branchId;
    }
    if (courseId != null && courseId.isNotEmpty) {
      queryParams['courseId'] = courseId;
    }
    if (teacherId != null && teacherId.isNotEmpty) {
      queryParams['teacherId'] = teacherId;
    }

    final response = await apiClient.get(
      ApiEndpoints.classes,
      queryParameters: queryParams,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ClassModel> getClassDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.classDetail(id));
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is Map<String, dynamic>) {
      return ClassModel.fromJson(data);
    }
    throw Exception('Dữ liệu lớp học không hợp lệ');
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
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'courseId': courseId,
      'levelId': levelId,
      'branchId': branchId,
      'status': status,
      'startDate': startDate,
      'scheduleDays': scheduleDays,
      'startTime': startTime,
      'endTime': endTime,
      'totalSessions': totalSessions,
      'maxCapacity': maxCapacity,
    };
    if (roomId != null) body['roomId'] = roomId;
    if (mainTeacherId != null) body['mainTeacherId'] = mainTeacherId;
    if (assistantTeacherId != null) {
      body['assistantTeacherId'] = assistantTeacherId;
    }
    if (tuitionFee != null) body['tuitionFee'] = tuitionFee;
    if (registrationOpenAt != null) {
      body['registrationOpenAt'] = registrationOpenAt;
    }
    if (registrationCloseAt != null) {
      body['registrationCloseAt'] = registrationCloseAt;
    }
    if (notes != null) body['notes'] = notes;

    final response = await apiClient.post(ApiEndpoints.classes, data: body);
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return ClassModel.fromJson(data);
    }
    throw Exception('Không thể tạo lớp học');
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
  }) async {
    final body = <String, dynamic>{};
    if (code != null) body['code'] = code;
    if (name != null) body['name'] = name;
    if (roomId != null) body['roomId'] = roomId;
    if (mainTeacherId != null) body['mainTeacherId'] = mainTeacherId;
    if (assistantTeacherId != null) {
      body['assistantTeacherId'] = assistantTeacherId;
    }
    if (status != null) body['status'] = status;
    if (startDate != null) body['startDate'] = startDate;
    if (scheduleDays != null) body['scheduleDays'] = scheduleDays;
    if (startTime != null) body['startTime'] = startTime;
    if (endTime != null) body['endTime'] = endTime;
    if (maxCapacity != null) body['maxCapacity'] = maxCapacity;
    if (tuitionFee != null) body['tuitionFee'] = tuitionFee;
    if (notes != null) body['notes'] = notes;

    final response = await apiClient.patch(
      ApiEndpoints.classDetail(id),
      data: body,
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return ClassModel.fromJson(data);
    }
    return getClassDetail(id);
  }

  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'studentId': studentId,
      'tuitionPaid': tuitionPaid,
    };
    if (notes != null) body['notes'] = notes;

    final response = await apiClient.post(
      ApiEndpoints.classStudents(classId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return ClassStudentModel.fromJson(data);
    }
    throw Exception('Không thể ghi danh học viên');
  }

  @override
  Future<void> removeStudent(String classId, String studentId) async {
    await apiClient.delete(ApiEndpoints.classStudentDelete(classId, studentId));
  }

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async {
    final response = await apiClient.get(ApiEndpoints.classSessions(classId));
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is List) {
      return data
          .map(
            (item) => ClassSessionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
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
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (date != null) body['date'] = date;
    if (startTime != null) body['startTime'] = startTime;
    if (endTime != null) body['endTime'] = endTime;
    if (roomId != null) body['roomId'] = roomId;
    if (teacherId != null) body['teacherId'] = teacherId;
    if (status != null) body['status'] = status;
    if (notes != null) body['notes'] = notes;

    final response = await apiClient.patch(
      ApiEndpoints.updateSession(sessionId),
      data: body,
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    if (data is Map<String, dynamic>) {
      return ClassSessionModel.fromJson(data);
    }
    throw Exception('Không thể cập nhật buổi học');
  }

  @override
  Future<List<ClassModel>> getMyClasses() async {
    final response = await apiClient.get(ApiEndpoints.myClasses);
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is List) {
      return data
          .map((item) => ClassModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;

    final response = await apiClient.get(
      ApiEndpoints.mySchedule,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;

    if (data is List) {
      return data
          .map(
            (item) => ClassSessionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}
