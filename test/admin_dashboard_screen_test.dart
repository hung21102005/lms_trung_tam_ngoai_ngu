import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/screens/admin_dashboard_screen.dart';

class FakeReportsRepository implements ReportsRepository {
  @override
  Future<DashboardOverviewModel> getDashboardOverview() async {
    return DashboardOverviewModel(
      totalStudents: 150,
      newStudentsThisMonth: 20,
      totalActiveClasses: 12,
      monthlyRevenue: 75000000,
      lastMonthRevenue: 60000000,
      monthlyRevenueGrowth: 25.0,
      totalDebts: 15000000,
      revenueTrend: const [
        MonthlyTrendItem(month: 'T5/2026', revenue: 50000000),
        MonthlyTrendItem(month: 'T6/2026', revenue: 75000000),
      ],
      courseDistribution: const [
        CourseDistributionItem(
          courseId: 'c1',
          courseName: 'IELTS Foundation',
          studentCount: 60,
        ),
      ],
      upcomingClasses: [
        UpcomingClassItem(
          id: 'cls-1',
          name: 'IELTS-F-01',
          courseName: 'IELTS Foundation',
          teacherName: 'Thầy David',
          startDate: DateTime(2026, 11, 1),
          enrolledCount: 15,
          maxStudents: 20,
        ),
      ],
      topDebtors: [
        TopDebtorItem(
          invoiceId: 'inv-1',
          invoiceCode: 'HD-2026-0001',
          studentName: 'Trần Văn Nam',
          studentCode: 'HV-01',
          className: 'IELTS Foundation',
          balance: 3500000,
          dueDate: DateTime(2026, 10, 30),
        ),
      ],
    );
  }

  @override
  Future<RevenueReportModel> getRevenueReport({
    int? year,
    String? branchId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceReportModel> getAttendanceReport({
    String? classId,
    String? startDate,
    String? endDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DebtsReportModel> getDebtsReport({
    String? branchId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async {
    return [];
  }

  @override
  Future<void> refreshDashboardCache() async {}
}

void main() {
  testWidgets('AdminDashboardScreen renders KPIs, charts, and tables', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeReportsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ReportsBloc>(
          create: (_) => ReportsBloc(repository: fakeRepo),
          child: const AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Báo Cáo & Dashboard Quản Trị'), findsOneWidget);

    // Verify KPI Cards
    expect(find.text('Học viên Active'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('+20 học viên mới tháng này'), findsOneWidget);

    expect(find.text('Lớp Hoạt Động'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    expect(find.text('Doanh thu tháng'), findsOneWidget);
    expect(find.text('Công nợ tồn đọng'), findsOneWidget);

    // Verify upcoming classes & top debtors
    expect(find.text('Lớp học sắp khai giảng'), findsOneWidget);
    expect(find.text('IELTS-F-01'), findsOneWidget);
    expect(find.text('Top công nợ cần đôn đốc'), findsOneWidget);
    expect(find.text('Trần Văn Nam'), findsOneWidget);
  });
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('Admin dashboard ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReportsBloc>(
            create: (_) => ReportsBloc(repository: FakeReportsRepository()),
            child: const AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin-dashboard-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(find.text('150'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
