import '../../data/models/report_model.dart';

abstract class ReportsRepository {
  Future<DashboardOverviewModel> getDashboardOverview();
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId});
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate});
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20});
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport();
  Future<void> refreshDashboardCache();
}

extension AcademicReportsRepositoryExtension on ReportsRepository {
  Future<AcademicReportModel> getAcademicReport({String? classId, String? examId}) {
    final dynamic self = this;
    try {
      return self.getAcademicReport(classId: classId, examId: examId) as Future<AcademicReportModel>;
    } catch (_) {
      throw UnimplementedError('getAcademicReport is not implemented on $runtimeType');
    }
  }
}
