import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/models/attendance_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/screens/attendance_mark_screen.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) async {
    return SessionAttendanceResponseModel(
      sessionId: sessionId,
      classId: 'class-1',
      className: 'IELTS Foundation T2-T4-T6',
      classCode: 'IELTS-F-01',
      sessionNumber: 1,
      title: 'Buổi 1: Unit 1 Greetings',
      date: '2026-10-18T00:00:00.000Z',
      startTime: '18:00',
      endTime: '19:30',
      status: 'SCHEDULED',
      summary: const AttendanceSummaryModel(
        totalEnrolled: 2,
        markedCount: 0,
        present: 0,
        absent: 0,
        late: 0,
        excused: 0,
        makeup: 0,
      ),
      students: [
        StudentAttendanceItemModel(
          studentId: 'student-1',
          userCode: 'HV001',
          fullName: 'Nguyễn Văn A',
          status: 'PRESENT',
        ),
        StudentAttendanceItemModel(
          studentId: 'student-2',
          userCode: 'HV002',
          fullName: 'Trần Thị B',
          status: 'PRESENT',
        ),
      ],
    );
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) async {
    return getSessionAttendance(sessionId);
  }

  @override
  Future<void> updateAttendance(
    String id, {
    String? status,
    String? notes,
  }) async {}

  @override
  Future<StudentAttendanceHistoryResponseModel> getStudentAttendance(
    String studentId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getClassAttendanceSummary(String classId) async {
    throw UnimplementedError();
  }

  @override
  Future<MakeupRequestModel> createMakeupRequest({
    required String originalSessionId,
    String? targetSessionId,
    String? reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MakeupRequestModel>> getMakeupRequests({
    String? status,
    String? studentId,
  }) async {
    return [];
  }

  @override
  Future<MakeupRequestModel> updateMakeupRequest(
    String id, {
    required String status,
    String? reason,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets(
    'AttendanceMarkScreen renders students list and status choice chips',
    (tester) async {
      final fakeRepo = FakeAttendanceRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AttendanceBloc>(
            create: (_) => AttendanceBloc(repository: fakeRepo),
            child: const AttendanceMarkScreen(sessionId: 'session-123'),
          ),
        ),
      );

      // Initial loading pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify session info is displayed
      expect(find.text('Điểm danh buổi học'), findsOneWidget);
      expect(find.text('Buổi 1: Unit 1 Greetings'), findsOneWidget);
      expect(find.text('Buổi 1'), findsOneWidget);

      // Verify students are rendered
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Trần Thị B'), findsOneWidget);

      // Verify status choice chips
      expect(find.text('Có mặt'), findsWidgets);
      expect(find.text('Đi muộn'), findsWidgets);
      expect(find.text('Vắng'), findsWidgets);
      expect(find.text('Có phép'), findsWidgets);

      // Verify submit button is displayed
      expect(find.text('Lưu & Hoàn Tất Điểm Danh'), findsOneWidget);
    },
  );
}
