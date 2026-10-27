import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/screens/teacher_reports_screen.dart';

class _Classes implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [
    ClassModel.fromJson({
      'id': 'class-1',
      'code': 'A1',
      'name': 'Lớp A1',
      'courseId': 'course-1',
      'levelId': 'level-1',
      'branchId': 'branch-1',
      'startTime': '16:00',
      'endTime': '17:30',
    }),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reports implements ReportsRepository {
  final filters = <String?>[];

  @override
  Future<AttendanceReportModel> getAttendanceReport({
    String? classId,
    String? startDate,
    String? endDate,
  }) async {
    filters.add(classId);
    return const AttendanceReportModel(
      totalRecords: 10,
      presentCount: 8,
      lateCount: 0,
      absentCount: 2,
      excusedCount: 0,
      makeupCount: 0,
      attendanceRate: 80,
      byClass: [],
    );
  }

  Future<AcademicReportModel> getAcademicReport({
    String? classId,
    String? examId,
  }) async {
    return AcademicReportModel.fromJson(<String, dynamic>{
      'totalAttempts': 5,
      'averageScore': 7.5,
      'passRate': 60,
      'classification': <String, dynamic>{},
      'topStudents': <dynamic>[],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Reports reports;

  setUp(() {
    reports = _Reports();
    getIt.registerSingleton<ClassesRepository>(_Classes());
    getIt.registerSingleton<ReportsRepository>(reports);
  });
  tearDown(() async => getIt.reset());

  testWidgets('báo cáo lấy dữ liệu và lọc theo lớp được phân công', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TeacherReportsScreen())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('80.0%'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((item) => item.data)
          .join(' | '),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lớp A1').last);
    await tester.pumpAndSettle();
    expect(reports.filters.last, 'class-1');
  });
}
