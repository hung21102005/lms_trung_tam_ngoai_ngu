import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/screens/debts_report_screen.dart';

class FakeDebtsReportsRepository implements ReportsRepository {
  @override
  Future<DashboardOverviewModel> getDashboardOverview() async {
    throw UnimplementedError();
  }

  @override
  Future<RevenueReportModel> getRevenueReport({int? year, String? branchId}) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceReportModel> getAttendanceReport({String? classId, String? startDate, String? endDate}) async {
    throw UnimplementedError();
  }

  @override
  Future<DebtsReportModel> getDebtsReport({String? branchId, String? search, int page = 1, int limit = 20}) async {
    return DebtsReportModel(
      items: [
        DebtInvoiceItem(
          id: 'inv-1',
          code: 'HD-2026-0001',
          studentName: 'Lê Hoàng Long',
          studentCode: 'HV-2026-0002',
          phone: '0909123456',
          className: 'IELTS Intensive',
          totalAmount: 6000000,
          paidAmount: 2000000,
          balance: 4000000,
          status: 'PARTIALLY_PAID',
          dueDate: DateTime(2026, 10, 1),
          isOverdue: true,
        ),
      ],
      total: 1,
      page: 1,
      limit: 20,
      summary: const DebtsSummaryModel(
        totalOutstanding: 4000000,
        totalInvoiced: 6000000,
        totalPaid: 2000000,
        overdueCount: 1,
      ),
    );
  }

  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async {
    return [];
  }

  @override
  Future<void> refreshDashboardCache() async {}
}

void main() {
  testWidgets('DebtsReportScreen renders summary cards and debt items correctly', (tester) async {
    final fakeRepo = FakeDebtsReportsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ReportsBloc>(
          create: (_) => ReportsBloc(repository: fakeRepo),
          child: const DebtsReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Báo Cáo Công Nợ Học Phí'), findsOneWidget);

    // Verify Summary
    expect(find.text('Tổng công nợ'), findsOneWidget);
    expect(find.text('Quá hạn'), findsWidgets);
    expect(find.text('1 hóa đơn'), findsOneWidget);

    // Verify Debt Item
    expect(find.text('Lê Hoàng Long'), findsOneWidget);
    expect(find.text('SĐT: 0909123456'), findsOneWidget);
  });
}
