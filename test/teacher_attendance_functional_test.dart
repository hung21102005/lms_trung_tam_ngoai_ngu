import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/models/attendance_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/teacher_attendance_view.dart';

class _AttendanceFake implements AttendanceRepository {
  bool locked = false;
  final batchPayloads = <List<Map<String, dynamic>>>[];
  final students = [
    StudentAttendanceItemModel(
      studentId: 'student-1',
      userCode: 'HV-001',
      fullName: 'Nguyễn Minh Anh',
    ),
    StudentAttendanceItemModel(
      studentId: 'student-2',
      userCode: 'HV-002',
      fullName: 'Trần Gia Bảo',
      status: 'LATE',
      checkInTime: '18:05',
    ),
  ];

  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) async {
    return SessionAttendanceResponseModel(
      sessionId: sessionId,
      classId: 'class-1',
      className: 'IELTS Foundation',
      classCode: 'IELTS-F-01',
      sessionNumber: 4,
      title: 'Writing Task 2',
      date: '2026-10-27',
      startTime: '18:00',
      endTime: '19:30',
      status: locked ? 'COMPLETED' : 'IN_PROGRESS',
      roomName: 'Phòng Smart 101',
      summary: const AttendanceSummaryModel(
        totalEnrolled: 2,
        markedCount: 1,
        present: 0,
        absent: 0,
        late: 1,
        excused: 0,
        makeup: 0,
      ),
      students: students,
    );
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) async {
    batchPayloads.add(students);
    if (lock) locked = true;
    return getSessionAttendance(sessionId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClassesFake implements ClassesRepository {
  _ClassesFake(this.attendance);

  final _AttendanceFake attendance;
  String? savedNotes;
  final statuses = <String?>[];

  ClassSessionModel get session => ClassSessionModel(
    id: 'session-1',
    classId: 'class-1',
    classCode: 'IELTS-F-01',
    className: 'IELTS Foundation',
    sessionNumber: 4,
    title: 'Writing Task 2',
    date: DateTime(2026, 10, 27),
    startTime: '18:00',
    endTime: '19:30',
    status: attendance.locked ? 'COMPLETED' : 'IN_PROGRESS',
    notes: savedNotes,
  );

  ClassModel get studyClass => const ClassModel(
    id: 'class-1',
    code: 'IELTS-F-01',
    name: 'IELTS Foundation',
    courseId: 'course-1',
    levelId: 'level-1',
    branchId: 'branch-1',
    startTime: '18:00',
    endTime: '19:30',
    status: 'IN_PROGRESS',
  );

  @override
  Future<List<ClassModel>> getMyClasses() async => [studyClass];

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async => [studyClass];

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async => [session];

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [
    session,
  ];

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
    statuses.add(status);
    if (status == 'COMPLETED') attendance.locked = true;
    if (notes != null) savedNotes = notes;
    return session;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AssignmentsFake implements AssignmentsRepository {
  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('normalizes API check-in timestamps to local HH:mm', () {
    final student = StudentAttendanceItemModel.fromJson({
      'studentId': 'student-1',
      'userCode': 'HV-001',
      'fullName': 'Nguyễn Minh Anh',
      'checkInTime': '2026-10-27T01:05:00.000Z',
    });

    expect(student.checkInTime, matches(RegExp(r'^\d{2}:\d{2}$')));
  });

  testWidgets('loads real session, locks attendance, and saves logbook', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final attendance = _AttendanceFake();
    final classes = _ClassesFake(attendance);
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          classesRepository: classes,
          attendanceRepository: attendance,
          assignmentsRepository: _AssignmentsFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('IELTS Foundation (IELTS-F-01)'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Trần Gia Bảo'), findsOneWidget);
    expect(find.text('2 HV'), findsOneWidget);

    await tester.tap(find.text('Tất cả có mặt'));
    await tester.pump();
    await tester.tap(find.text('Lưu & khóa điểm danh'));
    await tester.pumpAndSettle();

    expect(attendance.batchPayloads, hasLength(1));
    expect(
      attendance.batchPayloads.single.map((item) => item['status']),
      everyElement('PRESENT'),
    );
    expect(attendance.locked, isTrue);
    expect(classes.statuses, isNot(contains('COMPLETED')));
    expect(find.text('Điểm danh đã khóa'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(2), 'Unit 6: Opinion Essay');
    await tester.enterText(fields.at(3), 'Lớp học tập trung và tiến bộ tốt');
    await tester.enterText(fields.at(4), 'Hoàn thành bài viết 250 từ');
    final saveDraft = find.text('Lưu nháp sổ đầu bài');
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(saveDraft);
    await tester.pumpAndSettle();

    expect(classes.savedNotes, contains('TEACHING_LOG'));
    expect(classes.savedNotes, contains('Unit 6: Opinion Essay'));
    expect(classes.savedNotes, contains('Lớp học tập trung'));
    expect(find.text('Đã lưu nháp sổ đầu bài.'), findsOneWidget);
  });
}
