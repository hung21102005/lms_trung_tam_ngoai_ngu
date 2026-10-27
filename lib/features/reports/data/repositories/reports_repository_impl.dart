import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';
import '../models/report_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardOverviewModel> getDashboardOverview() {
    return remoteDataSource.getDashboardOverview();
  }

  @override
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId}) {
    return remoteDataSource.getRevenueReport(year: year, branchId: branchId);
  }

  @override
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate}) {
    return remoteDataSource.getAttendanceReport(classId: classId, startDate: startDate, endDate: endDate);
  }

  @override
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20}) {
    return remoteDataSource.getDebtsReport(branchId: branchId, search: search, page: page, limit: limit);
  }

  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() {
    return remoteDataSource.getTeacherWorkloadReport();
  }

  Future<AcademicReportModel> getAcademicReport({String? classId, String? examId}) {
    return remoteDataSource.getAcademicReport(classId: classId, examId: examId);
  }

  @override
  Future<void> refreshDashboardCache() {
    return remoteDataSource.refreshDashboardCache();
  }
}
