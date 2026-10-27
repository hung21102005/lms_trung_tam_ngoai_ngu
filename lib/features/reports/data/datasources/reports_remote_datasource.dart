import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/report_model.dart';

abstract class ReportsRemoteDataSource {
  Future<DashboardOverviewModel> getDashboardOverview();
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId});
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate});
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20});
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport();
  Future<AcademicReportModel> getAcademicReport({String? classId, String? examId});
  Future<void> refreshDashboardCache();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DashboardOverviewModel> getDashboardOverview() async {
    final response = await apiClient.get(ApiEndpoints.reportsDashboard);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return DashboardOverviewModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId}) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;
    if (branchId != null) queryParams['branchId'] = branchId;

    final response = await apiClient.get(
      ApiEndpoints.reportsRevenue,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return RevenueReportModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (classId != null) queryParams['classId'] = classId;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await apiClient.get(
      ApiEndpoints.reportsAttendance,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return AttendanceReportModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20}) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (branchId != null) queryParams['branchId'] = branchId;
    if (search != null) queryParams['search'] = search;

    final response = await apiClient.get(
      ApiEndpoints.reportsDebts,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return DebtsReportModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async {
    final response = await apiClient.get(ApiEndpoints.reportsTeacherWorkload);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list.map((item) => TeacherWorkloadModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<AcademicReportModel> getAcademicReport({String? classId, String? examId}) async {
    final queryParams = <String, dynamic>{};
    if (classId != null) queryParams['classId'] = classId;
    if (examId != null) queryParams['examId'] = examId;

    final response = await apiClient.get(
      ApiEndpoints.reportsAcademic,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return AcademicReportModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> refreshDashboardCache() async {
    await apiClient.post(ApiEndpoints.refreshDashboardCache);
  }
}
