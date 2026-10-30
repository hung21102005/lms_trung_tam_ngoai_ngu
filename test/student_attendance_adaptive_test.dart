import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/models/attendance_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/screens/my_attendance_screen.dart';

class _Attendance implements AttendanceRepository {
  @override
  Future<StudentAttendanceHistoryResponseModel> getStudentAttendance(
    String studentId,
  ) async => const StudentAttendanceHistoryResponseModel(
    summary: StudentAttendanceHistorySummary(
      totalSessions: 1,
      present: 1,
      late: 0,
      absent: 0,
      excused: 0,
      makeup: 0,
      attendanceRate: 100,
    ),
    records: [
      StudentAttendanceRecordModel(
        id: 'attendance-1',
        status: 'PRESENT',
        markedAt: '2026-10-27',
        sessionTitle: 'Speaking practice',
        sessionNumber: 1,
        sessionDate: '2026-10-27',
        startTime: '08:00',
        endTime: '09:30',
        className: 'IELTS Foundation',
        classCode: 'IELTS-F',
      ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('chuyên cần thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = AttendanceBloc(repository: _Attendance());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: MyAttendanceScreen(studentId: 's1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Speaking practice'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('student-attendance-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
