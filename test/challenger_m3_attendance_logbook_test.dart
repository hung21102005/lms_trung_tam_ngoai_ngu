import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:typed_data';

import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';

import 'package:lms_trung_tam_ngoai_ngu/features/attendance/data/models/attendance_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/teacher_attendance_view.dart';

// =============================================================================
// ADVERSARIAL FAKE REPOSITORIES WITH OBSERVABILITY ORACLES
// =============================================================================

class MockAttendanceRepository implements AttendanceRepository {
  final Map<String, SessionAttendanceResponseModel> sessionsData = {};
  final List<Map<String, dynamic>> batchCalls = [];

  void setSessionData(String sessionId, SessionAttendanceResponseModel data) {
    sessionsData[sessionId] = data;
  }

  @override
  Future<SessionAttendanceResponseModel> getSessionAttendance(
    String sessionId,
  ) async {
    if (sessionsData.containsKey(sessionId)) {
      return sessionsData[sessionId]!;
    }
    return SessionAttendanceResponseModel(
      sessionId: sessionId,
      classId: 'class-fallback',
      className: 'Fallback Class',
      classCode: 'FB-01',
      sessionNumber: 1,
      title: 'Fallback Session',
      date: '2026-10-19',
      startTime: '18:00',
      endTime: '20:00',
      status: 'SCHEDULED',
      summary: const AttendanceSummaryModel(
        totalEnrolled: 0,
        markedCount: 0,
        present: 0,
        absent: 0,
        late: 0,
        excused: 0,
        makeup: 0,
      ),
      students: [],
    );
  }

  @override
  Future<SessionAttendanceResponseModel> batchMarkAttendance(
    String sessionId,
    List<Map<String, dynamic>> students, {
    bool lock = false,
  }) async {
    batchCalls.add({
      'sessionId': sessionId,
      'students': students,
      'lock': lock,
    });

    final existing = await getSessionAttendance(sessionId);
    final updatedStudents = existing.students.map((s) {
      final match = students.firstWhere(
        (p) => p['studentId'] == s.studentId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        s.status = match['status'] as String?;
        if (match.containsKey('notes')) {
          s.notes = match['notes'] as String?;
        }
      }
      return s;
    }).toList();

    final updated = SessionAttendanceResponseModel(
      sessionId: existing.sessionId,
      classId: existing.classId,
      className: existing.className,
      classCode: existing.classCode,
      sessionNumber: existing.sessionNumber,
      title: existing.title,
      date: existing.date,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: existing.status,
      summary: existing.summary,
      students: updatedStudents,
    );
    sessionsData[sessionId] = updated;
    return updated;
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
  ) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getClassAttendanceSummary(
    String classId,
  ) async => throw UnimplementedError();

  @override
  Future<MakeupRequestModel> createMakeupRequest({
    required String originalSessionId,
    String? targetSessionId,
    String? reason,
  }) async => throw UnimplementedError();

  @override
  Future<List<MakeupRequestModel>> getMakeupRequests({
    String? status,
    String? studentId,
  }) async => [];

  @override
  Future<MakeupRequestModel> updateMakeupRequest(
    String id, {
    required String status,
    String? reason,
  }) async => throw UnimplementedError();
}

class MockAssignmentsRepository implements AssignmentsRepository {
  @override
  Future<AssignmentAttachmentModel> uploadAttachment(String fileName, Uint8List bytes) async =>
      AssignmentAttachmentModel(name: fileName, url: '/test/$fileName', fileType: 'DOCUMENT');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockClassesRepository implements ClassesRepository {
  List<ClassModel> myClasses = [];
  final Map<String, ClassModel> classDetails = {};
  final List<Map<String, dynamic>> updateSessionCalls = [];

  void setMyClasses(List<ClassModel> classes) {
    myClasses = classes;
  }

  void setClassDetail(String classId, ClassModel detail) {
    classDetails[classId] = detail;
  }

  @override
  Future<List<ClassModel>> getMyClasses() async => myClasses;

  @override
  Future<ClassModel> getClassDetail(String id) async {
    if (classDetails.containsKey(id)) {
      return classDetails[id]!;
    }
    return ClassModel(
      id: id,
      code: 'CLS-DEF',
      name: 'Default Class',
      courseId: 'crs-def',
      levelId: 'lvl-def',
      branchId: 'br-def',
      startTime: '18:00',
      endTime: '20:00',
    );
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
    updateSessionCalls.add({
      'sessionId': sessionId,
      'title': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'roomId': roomId,
      'teacherId': teacherId,
      'status': status,
      'notes': notes,
    });

    return ClassSessionModel(
      id: sessionId,
      classId: 'class-1',
      title: title ?? 'Updated Title',
      startTime: startTime ?? '18:00',
      endTime: endTime ?? '20:00',
      notes: notes,
      status: status ?? 'IN_PROGRESS',
    );
  }

  @override
  Future<List<ClassModel>> getClasses({
    String? search,
    String? status,
    String? branchId,
    String? courseId,
    String? teacherId,
    int page = 1,
    int limit = 50,
  }) async => myClasses;

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
  }) async => throw UnimplementedError();

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
    String? registrationOpenAt,
    String? registrationCloseAt,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<ClassStudentModel> enrollStudent(
    String classId, {
    required String studentId,
    double tuitionPaid = 0,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<void> removeStudent(String classId, String studentId) async {}

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [];

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async => [];
}

// =============================================================================
// TEST DATA FIXTURES
// =============================================================================

ClassModel createClassFixture({
  required String id,
  required String code,
  required String name,
  required List<ClassSessionModel> sessions,
}) {
  return ClassModel(
    id: id,
    code: code,
    name: name,
    courseId: 'crs-1',
    courseTitle: 'Khóa luyện IELTS Pro',
    levelId: 'lvl-1',
    levelName: 'Advanced',
    branchId: 'br-1',
    branchName: 'Chi nhánh Quận 1',
    roomId: 'room-101',
    roomName: 'Phòng Lab A',
    startTime: '18:00',
    endTime: '20:00',
    status: 'IN_PROGRESS',
    totalSessions: sessions.length,
    sessions: sessions,
  );
}

ClassSessionModel createSessionFixture({
  required String id,
  required String classId,
  required int sessionNumber,
  required String title,
  String status = 'SCHEDULED',
  String? notes,
  DateTime? date,
}) {
  return ClassSessionModel(
    id: id,
    classId: classId,
    sessionNumber: sessionNumber,
    title: title,
    startTime: '18:00',
    endTime: '20:00',
    status: status,
    notes: notes,
    date: date ?? DateTime(2026, 10, 19),
  );
}

SessionAttendanceResponseModel createAttendanceResponseFixture({
  required String sessionId,
  required String classId,
  required String classCode,
  required String className,
  required int sessionNumber,
  required String title,
  required List<StudentAttendanceItemModel> students,
}) {
  final present = students.where((s) => s.status == 'PRESENT').length;
  final lateCount = students.where((s) => s.status == 'LATE').length;
  final excused = students.where((s) => s.status == 'EXCUSED').length;
  final absent = students.where((s) => s.status == 'ABSENT').length;

  return SessionAttendanceResponseModel(
    sessionId: sessionId,
    classId: classId,
    className: className,
    classCode: classCode,
    sessionNumber: sessionNumber,
    title: title,
    date: '2026-10-19',
    startTime: '18:00',
    endTime: '20:00',
    status: 'IN_PROGRESS',
    summary: AttendanceSummaryModel(
      totalEnrolled: students.length,
      markedCount: present + lateCount + excused + absent,
      present: present,
      absent: absent,
      late: lateCount,
      excused: excused,
      makeup: 0,
    ),
    students: students,
  );
}

// =============================================================================
// MAIN EMPIRICAL CHALLENGER TEST SUITE
// =============================================================================

void main() {
  late MockClassesRepository classesRepo;
  late MockAttendanceRepository attendanceRepo;
  late ClassesBloc classesBloc;
  late AttendanceBloc attendanceBloc;

  setUp(() {
    classesRepo = MockClassesRepository();
    attendanceRepo = MockAttendanceRepository();
    classesBloc = ClassesBloc(repository: classesRepo);
    attendanceBloc = AttendanceBloc(repository: attendanceRepo);

    final getIt = GetIt.instance;
    if (getIt.isRegistered<ClassesBloc>()) getIt.unregister<ClassesBloc>();
    if (getIt.isRegistered<AttendanceBloc>())
      getIt.unregister<AttendanceBloc>();
    if (getIt.isRegistered<ClassesRepository>()) getIt.unregister<ClassesRepository>();
    if (getIt.isRegistered<AttendanceRepository>()) getIt.unregister<AttendanceRepository>();
    if (getIt.isRegistered<AssignmentsRepository>()) getIt.unregister<AssignmentsRepository>();
    getIt.registerFactory<ClassesBloc>(() => classesBloc);
    getIt.registerFactory<AttendanceBloc>(() => attendanceBloc);
    getIt.registerSingleton<ClassesRepository>(classesRepo);
    getIt.registerSingleton<AttendanceRepository>(attendanceRepo);
    getIt.registerSingleton<AssignmentsRepository>(MockAssignmentsRepository());
  });

  tearDown(() {
    classesBloc.close();
    attendanceBloc.close();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ClassesBloc>()) getIt.unregister<ClassesBloc>();
    if (getIt.isRegistered<AttendanceBloc>())
      getIt.unregister<AttendanceBloc>();
    if (getIt.isRegistered<ClassesRepository>()) getIt.unregister<ClassesRepository>();
    if (getIt.isRegistered<AttendanceRepository>()) getIt.unregister<AttendanceRepository>();
    if (getIt.isRegistered<AssignmentsRepository>()) getIt.unregister<AssignmentsRepository>();
  });

  Widget buildSubject({Size size = const Size(1024, 768)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ClassesBloc>.value(value: classesBloc),
            BlocProvider<AttendanceBloc>.value(value: attendanceBloc),
          ],
          child: const Scaffold(body: TeacherAttendanceView()),
        ),
      ),
    );
  }

  void setupScreenSize(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  // ===========================================================================
  // GROUP 1: EMPIRICAL 4 ATTENDANCE STATUSES TOGGLING & ORACLE CALCULATIONS
  // ===========================================================================
  group('1. Empirical 4-Status Attendance Toggling & Calculation Oracle', () {
    testWidgets(
      '1.1 Initial State: displays correct counts and rate calculation',
      (tester) async {
        final session1 = createSessionFixture(
          id: 'sess-101',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Unit 1: Foundations',
        );
        final class1 = createClassFixture(
          id: 'cls-1',
          code: 'IELTS-A',
          name: 'IELTS Advanced 7.0',
          sessions: [session1],
        );

        final students = [
          StudentAttendanceItemModel(
            studentId: 'st-1',
            userCode: 'HV001',
            fullName: 'Nguyễn Văn An',
            status: 'PRESENT',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-2',
            userCode: 'HV002',
            fullName: 'Trần Thị Bình',
            status: 'LATE',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-3',
            userCode: 'HV003',
            fullName: 'Lê Hoàng Cúc',
            status: 'EXCUSED',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-4',
            userCode: 'HV004',
            fullName: 'Phạm Minh Đức',
            status: 'ABSENT',
          ),
        ];

        classesRepo.setMyClasses([class1]);
        classesRepo.setClassDetail('cls-1', class1);
        attendanceRepo.setSessionData(
          'sess-101',
          createAttendanceResponseFixture(
            sessionId: 'sess-101',
            classId: 'cls-1',
            classCode: 'IELTS-A',
            className: 'IELTS Advanced 7.0',
            sessionNumber: 1,
            title: 'Unit 1: Foundations',
            students: students,
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify header rendered
        expect(find.text('Điểm Danh & Sổ Đầu Bài'), findsOneWidget);

        // Verify Metrics Chips:
        // Sĩ số: 4, Có mặt: 1, Đi trễ: 1, Vắng phép: 1, Vắng K.Phép: 1
        expect(find.text('4'), findsWidgets); // Sĩ số
        expect(find.text('Sĩ số lớp'), findsOneWidget);
        expect(find.text('Có mặt'), findsWidgets);
        expect(find.text('Đi trễ'), findsOneWidget);
        expect(find.text('Vắng phép'), findsOneWidget);
        expect(find.text('Vắng K.Phép'), findsOneWidget);

        // Verify attendance rate formula: (present + late) / total = (1 + 1)/4 = 50.0%
        expect(find.text('Tỷ lệ chuyên cần: 50.0%'), findsOneWidget);
      },
    );

    testWidgets(
      '1.2 Full 4-Status Cycle: PRESENT -> LATE -> EXCUSED -> ABSENT -> PRESENT',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-1',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Session 1',
        );
        final classItem = createClassFixture(
          id: 'cls-1',
          code: 'IELTS-1',
          name: 'Class 1',
          sessions: [session],
        );

        final student = StudentAttendanceItemModel(
          studentId: 'st-1',
          userCode: 'HV001',
          fullName: 'Nguyễn Văn An',
          status: 'PRESENT',
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-1', classItem);
        attendanceRepo.setSessionData(
          'sess-1',
          createAttendanceResponseFixture(
            sessionId: 'sess-1',
            classId: 'cls-1',
            classCode: 'IELTS-1',
            className: 'Class 1',
            sessionNumber: 1,
            title: 'Session 1',
            students: [student],
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Rate initially 100.0% (1 PRESENT / 1)
        expect(find.text('Tỷ lệ chuyên cần: 100.0%'), findsOneWidget);

        // 1. Toggle to LATE ("Trễ")
        await tester.tap(find.text('Trễ').first);
        await tester.pump();
        expect(student.status, equals('LATE'));
        // Rate remains 100.0% since late counts as present towards attendance rate
        expect(find.text('Tỷ lệ chuyên cần: 100.0%'), findsOneWidget);

        // 2. Toggle to EXCUSED ("Phép")
        await tester.tap(find.text('Phép').first);
        await tester.pump();
        expect(student.status, equals('EXCUSED'));
        // Rate drops to 0.0% (0 / 1)
        expect(find.text('Tỷ lệ chuyên cần: 0.0%'), findsOneWidget);

        // 3. Toggle to ABSENT ("K.Phép")
        await tester.tap(find.text('K.Phép').first);
        await tester.pump();
        expect(student.status, equals('ABSENT'));
        expect(find.text('Tỷ lệ chuyên cần: 0.0%'), findsOneWidget);

        // 4. Toggle back to PRESENT ("Có mặt")
        final coMatButtons = find.widgetWithText(Container, 'Có mặt');
        await tester.tap(coMatButtons.first);
        await tester.pump();
        expect(student.status, equals('PRESENT'));
        expect(find.text('Tỷ lệ chuyên cần: 100.0%'), findsOneWidget);
      },
    );

    testWidgets(
      '1.3 Quick Action: "Có mặt tất cả" toggles all students to PRESENT and updates rate to 100%',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-1',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Session 1',
        );
        final classItem = createClassFixture(
          id: 'cls-1',
          code: 'IELTS-1',
          name: 'Class 1',
          sessions: [session],
        );

        final students = [
          StudentAttendanceItemModel(
            studentId: 'st-1',
            userCode: 'HV001',
            fullName: 'Học Viên 1',
            status: 'ABSENT',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-2',
            userCode: 'HV002',
            fullName: 'Học Viên 2',
            status: 'EXCUSED',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-3',
            userCode: 'HV003',
            fullName: 'Học Viên 3',
            status: 'LATE',
          ),
        ];

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-1', classItem);
        attendanceRepo.setSessionData(
          'sess-1',
          createAttendanceResponseFixture(
            sessionId: 'sess-1',
            classId: 'cls-1',
            classCode: 'IELTS-1',
            className: 'Class 1',
            sessionNumber: 1,
            title: 'Session 1',
            students: students,
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Before: 1 late out of 3 = 33.3%
        expect(find.text('Tỷ lệ chuyên cần: 33.3%'), findsOneWidget);

        // Tap "Có mặt tất cả"
        final markAllBtn = find.text('Có mặt tất cả');
        expect(markAllBtn, findsOneWidget);
        await tester.tap(markAllBtn);
        await tester.pump();

        // All students are now PRESENT
        for (final s in students) {
          expect(s.status, equals('PRESENT'));
        }
        expect(find.text('Tỷ lệ chuyên cần: 100.0%'), findsOneWidget);
        expect(find.text('Đã đánh dấu tất cả học viên có mặt'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // GROUP 2: DYNAMIC CLASS & SESSION SELECTION & STATE ISOLATION
  // ===========================================================================
  group('2. Dynamic Class and Session Selection', () {
    testWidgets(
      '2.1 Switching sessions updates logbook controllers and attendance data',
      (tester) async {
        final session1 = createSessionFixture(
          id: 'sess-1',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Buổi 1: Tổng quan IELTS',
          notes: '[Bài tập]: Làm Cam 18 Test 1\n[Nhận xét]: Cả lớp tích cực',
        );
        final session2 = createSessionFixture(
          id: 'sess-2',
          classId: 'cls-1',
          sessionNumber: 2,
          title: 'Buổi 2: Listening Section 1',
          notes: '[Bài tập]: Nghe lại bài 2\n[Nhận xét]: Cần chú ý spelling',
        );
        final classItem = createClassFixture(
          id: 'cls-1',
          code: 'IELTS-01',
          name: 'IELTS Intensive',
          sessions: [session1, session2],
        );

        final studentsSess1 = [
          StudentAttendanceItemModel(
            studentId: 'st-1',
            userCode: 'HV01',
            fullName: 'Học viên A',
            status: 'PRESENT',
          ),
        ];
        final studentsSess2 = [
          StudentAttendanceItemModel(
            studentId: 'st-1',
            userCode: 'HV01',
            fullName: 'Học viên A',
            status: 'LATE',
          ),
        ];

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-1', classItem);
        attendanceRepo.setSessionData(
          'sess-1',
          createAttendanceResponseFixture(
            sessionId: 'sess-1',
            classId: 'cls-1',
            classCode: 'IELTS-01',
            className: 'IELTS Intensive',
            sessionNumber: 1,
            title: session1.title,
            students: studentsSess1,
          ),
        );
        attendanceRepo.setSessionData(
          'sess-2',
          createAttendanceResponseFixture(
            sessionId: 'sess-2',
            classId: 'cls-1',
            classCode: 'IELTS-01',
            className: 'IELTS Intensive',
            sessionNumber: 2,
            title: session2.title,
            students: studentsSess2,
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially session 1 is selected
        expect(find.text('Buổi 1: Tổng quan IELTS'), findsWidgets);
        expect(find.text('Làm Cam 18 Test 1'), findsOneWidget);
        expect(find.text('Cả lớp tích cực'), findsOneWidget);

        // Switch session to Session 2 via Dropdown
        final sessionDropdownFinder = find.byKey(
          const ValueKey('session_sess-1'),
        );
        expect(sessionDropdownFinder, findsOneWidget);
        await tester.tap(sessionDropdownFinder);
        await tester.pumpAndSettle();

        final session2Item = find.textContaining('Buổi 2').last;
        await tester.tap(session2Item);
        await tester.pumpAndSettle();

        // Logbook fields must update to session 2's data
        expect(find.text('Buổi 2: Listening Section 1'), findsWidgets);
        expect(find.text('Nghe lại bài 2'), findsOneWidget);
        expect(find.text('Cần chú ý spelling'), findsOneWidget);
        expect(studentsSess2.first.status, equals('LATE'));
      },
    );

    testWidgets(
      '2.2 Switching classes resets sessions and clears old state cleanly',
      (tester) async {
        final classASess1 = createSessionFixture(
          id: 'sess-a1',
          classId: 'cls-A',
          sessionNumber: 1,
          title: 'Class A Sess 1',
        );
        final classA = createClassFixture(
          id: 'cls-A',
          code: 'CLS-A',
          name: 'Lớp Sáng',
          sessions: [classASess1],
        );

        final classBSess1 = createSessionFixture(
          id: 'sess-b1',
          classId: 'cls-B',
          sessionNumber: 1,
          title: 'Class B Sess 1',
        );
        final classB = createClassFixture(
          id: 'cls-B',
          code: 'CLS-B',
          name: 'Lớp Tối',
          sessions: [classBSess1],
        );

        classesRepo.setMyClasses([classA, classB]);
        classesRepo.setClassDetail('cls-A', classA);
        classesRepo.setClassDetail('cls-B', classB);

        final studentsA = [
          StudentAttendanceItemModel(
            studentId: 'st-a1',
            userCode: 'HVA1',
            fullName: 'Học Viên Lớp A',
            status: 'PRESENT',
          ),
        ];
        final studentsB = [
          StudentAttendanceItemModel(
            studentId: 'st-b1',
            userCode: 'HVB1',
            fullName: 'Học Viên Lớp B',
            status: 'EXCUSED',
          ),
        ];

        attendanceRepo.setSessionData(
          'sess-a1',
          createAttendanceResponseFixture(
            sessionId: 'sess-a1',
            classId: 'cls-A',
            classCode: 'CLS-A',
            className: 'Lớp Sáng',
            sessionNumber: 1,
            title: 'Class A Sess 1',
            students: studentsA,
          ),
        );
        attendanceRepo.setSessionData(
          'sess-b1',
          createAttendanceResponseFixture(
            sessionId: 'sess-b1',
            classId: 'cls-B',
            classCode: 'CLS-B',
            className: 'Lớp Tối',
            sessionNumber: 1,
            title: 'Class B Sess 1',
            students: studentsB,
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Học Viên Lớp A'), findsOneWidget);
        expect(find.text('Học Viên Lớp B'), findsNothing);

        // Switch to Class B via class dropdown
        final classDropdownFinder = find.byKey(const ValueKey('class_cls-A'));
        expect(classDropdownFinder, findsOneWidget);
        await tester.tap(classDropdownFinder);
        await tester.pumpAndSettle();

        final classBItem = find.text('CLS-B - Lớp Tối').last;
        await tester.tap(classBItem);
        await tester.pumpAndSettle();

        // Verify Class B is now active and student B is shown
        expect(find.text('Học Viên Lớp B'), findsOneWidget);
        expect(find.text('Học Viên Lớp A'), findsNothing);
      },
    );
  });

  // ===========================================================================
  // GROUP 3: DIGITAL LOGBOOK PARSING, EDITING & PERSISTENCE
  // ===========================================================================
  group('3. Digital Logbook Topic & Homework Input Persistence', () {
    testWidgets('3.1 Formatted logbook regex parsing with multiline content', (
      tester,
    ) async {
      const complexNotes =
          '[Bài tập]: 1. Complete Unit 4 Workbook\n2. Record Speaking Task 2\n[Nhận xét]: Lớp học sôi nổi, cần ôn thêm phần Relative Clauses.';
      final session = createSessionFixture(
        id: 'sess-1',
        classId: 'cls-1',
        sessionNumber: 1,
        title: 'Unit 4: Advanced Writing',
        notes: complexNotes,
      );
      final classItem = createClassFixture(
        id: 'cls-1',
        code: 'IELTS-4',
        name: 'Class 4',
        sessions: [session],
      );

      classesRepo.setMyClasses([classItem]);
      classesRepo.setClassDetail('cls-1', classItem);
      attendanceRepo.setSessionData(
        'sess-1',
        createAttendanceResponseFixture(
          sessionId: 'sess-1',
          classId: 'cls-1',
          classCode: 'IELTS-4',
          className: 'Class 4',
          sessionNumber: 1,
          title: session.title,
          students: [],
        ),
      );

      await tester.pumpWidget(buildSubject());
      classesBloc.add(const FetchMyClasses());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check text fields
      expect(find.text('Unit 4: Advanced Writing'), findsWidgets);
      expect(
        find.text('1. Complete Unit 4 Workbook\n2. Record Speaking Task 2'),
        findsOneWidget,
      );
      expect(
        find.text('Lớp học sôi nổi, cần ôn thêm phần Relative Clauses.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '3.2 Unformatted raw notes fallback to remarks field gracefully',
      (tester) async {
        const rawNotes =
            'Buổi học bù từ thứ 7 tuần trước, lớp học bình thường.';
        final session = createSessionFixture(
          id: 'sess-raw',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Make-up Session',
          notes: rawNotes,
        );
        final classItem = createClassFixture(
          id: 'cls-1',
          code: 'CLS-1',
          name: 'Class 1',
          sessions: [session],
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-1', classItem);
        attendanceRepo.setSessionData(
          'sess-raw',
          createAttendanceResponseFixture(
            sessionId: 'sess-raw',
            classId: 'cls-1',
            classCode: 'CLS-1',
            className: 'Class 1',
            sessionNumber: 1,
            title: session.title,
            students: [],
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(rawNotes), findsOneWidget);
      },
    );

    testWidgets(
      '3.3 Saving logbook dispatches UpdateSessionEvent with combined formatted notes and topic',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-save',
          classId: 'cls-save',
          sessionNumber: 3,
          title: 'Initial Topic',
        );
        final classItem = createClassFixture(
          id: 'cls-save',
          code: 'CLS-S',
          name: 'Save Class',
          sessions: [session],
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-save', classItem);
        attendanceRepo.setSessionData(
          'sess-save',
          createAttendanceResponseFixture(
            sessionId: 'sess-save',
            classId: 'cls-save',
            classCode: 'CLS-S',
            className: 'Save Class',
            sessionNumber: 3,
            title: session.title,
            students: [
              StudentAttendanceItemModel(
                studentId: 'st-1',
                userCode: 'HV01',
                fullName: 'Học viên A',
                status: 'PRESENT',
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Enter new topic
        final topicField = find.widgetWithText(
          TextField,
          'Chủ đề / Giáo án buổi học',
        );
        await tester.enterText(topicField, 'IELTS Speaking Part 3 Strategy');

        // Enter homework
        final hwField = find.widgetWithText(
          TextField,
          'Bài tập về nhà đã giao',
        );
        await tester.enterText(hwField, 'Luyện nói 5 chủ đề xã hội');

        // Enter remark
        final remarkField = find.widgetWithText(
          TextField,
          'Nhận xét tình hình buổi học',
        );
        await tester.enterText(
          remarkField,
          'Cần cải thiện độ trôi chảy Fluency',
        );

        // Tap Save button "Lưu Sổ & Chốt Điểm Danh"
        final saveButton = find.text('Lưu Sổ & Chốt Điểm Danh');
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify ClassesRepository.updateSession was invoked with exact formatted combinedNotes
        expect(classesRepo.updateSessionCalls.length, equals(1));
        final call = classesRepo.updateSessionCalls.first;
        expect(call['sessionId'], equals('sess-save'));
        expect(call['title'], equals('IELTS Speaking Part 3 Strategy'));
        expect(
          call['notes'],
          equals(
            '[Bài tập]: Luyện nói 5 chủ đề xã hội\n[Nhận xét]: Cần cải thiện độ trôi chảy Fluency',
          ),
        );
      },
    );
  });

  // ===========================================================================
  // GROUP 4: BATCH ATTENDANCE PAYLOAD VERIFICATION
  // ===========================================================================
  group('4. Batch Attendance Payload Verification', () {
    testWidgets(
      '4.1 Batch payload strictly matches { students: [{ studentId, status, notes }] }',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-batch',
          classId: 'cls-1',
          sessionNumber: 1,
          title: 'Batch Session',
        );
        final classItem = createClassFixture(
          id: 'cls-1',
          code: 'CLS-B',
          name: 'Batch Class',
          sessions: [session],
        );

        final students = [
          StudentAttendanceItemModel(
            studentId: 'st-01',
            userCode: 'HV01',
            fullName: 'Học viên 1',
            status: 'PRESENT',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-02',
            userCode: 'HV02',
            fullName: 'Học viên 2',
            status: 'LATE',
            notes: 'Đi trễ 15p',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-03',
            userCode: 'HV03',
            fullName: 'Học viên 3',
            status: 'ABSENT',
          ),
          StudentAttendanceItemModel(
            studentId: 'st-04',
            userCode: 'HV04',
            fullName: 'Học viên 4',
            status: 'EXCUSED',
            notes: 'Bị ốm có đơn',
          ),
        ];

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-1', classItem);
        attendanceRepo.setSessionData(
          'sess-batch',
          createAttendanceResponseFixture(
            sessionId: 'sess-batch',
            classId: 'cls-1',
            classCode: 'CLS-B',
            className: 'Batch Class',
            sessionNumber: 1,
            title: session.title,
            students: students,
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap Save
        final saveBtn = find.text('Lưu Sổ & Chốt Điểm Danh');
        await tester.tap(saveBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verify captured batch call
        expect(attendanceRepo.batchCalls.length, equals(1));
        final batchCall = attendanceRepo.batchCalls.first;
        expect(batchCall['sessionId'], equals('sess-batch'));

        final payloadList = batchCall['students'] as List<Map<String, dynamic>>;
        expect(payloadList.length, equals(4));

        // Student 1: PRESENT
        expect(payloadList[0]['studentId'], equals('st-01'));
        expect(payloadList[0]['status'], equals('PRESENT'));

        // Student 2: LATE with notes
        expect(payloadList[1]['studentId'], equals('st-02'));
        expect(payloadList[1]['status'], equals('LATE'));
        expect(payloadList[1]['notes'], equals('Đi trễ 15p'));

        // Student 3: ABSENT
        expect(payloadList[2]['studentId'], equals('st-03'));
        expect(payloadList[2]['status'], equals('ABSENT'));

        // Student 4: EXCUSED with notes
        expect(payloadList[3]['studentId'], equals('st-04'));
        expect(payloadList[3]['status'], equals('EXCUSED'));
        expect(payloadList[3]['notes'], equals('Bị ốm có đơn'));
      },
    );
  });

  // ===========================================================================
  // GROUP 5: VIEWPORT RESPONSIVENESS & ZERO OVERFLOW PROFILING
  // ===========================================================================
  group('5. Viewport Responsiveness & Layout Integrity (Zero Overflows)', () {
    testWidgets(
      '5.1 Mobile Form Factor (393 x 852 - Android Pixel 9): Zero Overflows',
      (tester) async {
        setupScreenSize(tester, 393, 852);

        final session = createSessionFixture(
          id: 'sess-m',
          classId: 'cls-m',
          sessionNumber: 1,
          title: 'Mobile Session',
        );
        final classItem = createClassFixture(
          id: 'cls-m',
          code: 'MOB-01',
          name: 'Mobile Class',
          sessions: [session],
        );
        final students = List.generate(
          5,
          (i) => StudentAttendanceItemModel(
            studentId: 'st-$i',
            userCode: 'HV00$i',
            fullName: 'Học Viên Di Động $i',
            phone: '090123456$i',
            status: 'PRESENT',
          ),
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-m', classItem);
        attendanceRepo.setSessionData(
          'sess-m',
          createAttendanceResponseFixture(
            sessionId: 'sess-m',
            classId: 'cls-m',
            classCode: 'MOB-01',
            className: 'Mobile Class',
            sessionNumber: 1,
            title: session.title,
            students: students,
          ),
        );

        await tester.pumpWidget(buildSubject(size: const Size(393, 852)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Điểm Danh & Sổ Đầu Bài'), findsOneWidget);
        expect(find.text('Học Viên Di Động 0'), findsOneWidget);
      },
    );

    testWidgets('5.2 Web Desktop Form Factor (1024 x 768): Zero Overflows', (
      tester,
    ) async {
      setupScreenSize(tester, 1024, 768);

      final session = createSessionFixture(
        id: 'sess-d',
        classId: 'cls-d',
        sessionNumber: 1,
        title: 'Desktop Session',
      );
      final classItem = createClassFixture(
        id: 'cls-d',
        code: 'DESK-01',
        name: 'Desktop Class',
        sessions: [session],
      );
      final students = List.generate(
        8,
        (i) => StudentAttendanceItemModel(
          studentId: 'st-$i',
          userCode: 'HV00$i',
          fullName: 'Học Viên Desktop $i',
          phone: '090123456$i',
          status: 'PRESENT',
        ),
      );

      classesRepo.setMyClasses([classItem]);
      classesRepo.setClassDetail('cls-d', classItem);
      attendanceRepo.setSessionData(
        'sess-d',
        createAttendanceResponseFixture(
          sessionId: 'sess-d',
          classId: 'cls-d',
          classCode: 'DESK-01',
          className: 'Desktop Class',
          sessionNumber: 1,
          title: session.title,
          students: students,
        ),
      );

      await tester.pumpWidget(buildSubject(size: const Size(1024, 768)));
      classesBloc.add(const FetchMyClasses());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Sổ Đầu Bài & Nội Dung Giảng Dạy'), findsOneWidget);
    });

    testWidgets(
      '5.3 Boundary Breakpoint (900px Mobile vs 901px Desktop): Zero Overflows',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-b',
          classId: 'cls-b',
          sessionNumber: 1,
          title: 'Boundary Session',
        );
        final classItem = createClassFixture(
          id: 'cls-b',
          code: 'BND-01',
          name: 'Boundary Class',
          sessions: [session],
        );
        final students = [
          StudentAttendanceItemModel(
            studentId: 'st-1',
            userCode: 'HV01',
            fullName: 'Học Viên Boundary',
            status: 'PRESENT',
          ),
        ];

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-b', classItem);
        attendanceRepo.setSessionData(
          'sess-b',
          createAttendanceResponseFixture(
            sessionId: 'sess-b',
            classId: 'cls-b',
            classCode: 'BND-01',
            className: 'Boundary Class',
            sessionNumber: 1,
            title: session.title,
            students: students,
          ),
        );

        // Test width 900 (Mobile)
        setupScreenSize(tester, 900, 800);
        await tester.pumpWidget(buildSubject(size: const Size(900, 800)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        // Test width 901 (Desktop)
        setupScreenSize(tester, 901, 800);
        await tester.pumpWidget(buildSubject(size: const Size(901, 800)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5.4 High-Resolution Web Desktop (1440 x 900): Zero Overflows',
      (tester) async {
        setupScreenSize(tester, 1440, 900);

        final session = createSessionFixture(
          id: 'sess-wide',
          classId: 'cls-wide',
          sessionNumber: 1,
          title: 'Wide Session',
        );
        final classItem = createClassFixture(
          id: 'cls-wide',
          code: 'WIDE-01',
          name: 'Wide Class',
          sessions: [session],
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-wide', classItem);
        attendanceRepo.setSessionData(
          'sess-wide',
          createAttendanceResponseFixture(
            sessionId: 'sess-wide',
            classId: 'cls-wide',
            classCode: 'WIDE-01',
            className: 'Wide Class',
            sessionNumber: 1,
            title: session.title,
            students: [
              StudentAttendanceItemModel(
                studentId: 'st-w',
                userCode: 'HVW',
                fullName: 'Wide Student',
                status: 'PRESENT',
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildSubject(size: const Size(1440, 900)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5.5 Desktop Canvas inside TeacherHomeScreen (width: 764px canvas): Zero Overflows',
      (tester) async {
        // 1024px desktop width minus 260px sidebar = 764px available content canvas
        setupScreenSize(tester, 764, 768);

        final session = createSessionFixture(
          id: 'sess-canvas',
          classId: 'cls-c',
          sessionNumber: 1,
          title: 'Canvas Session',
        );
        final classItem = createClassFixture(
          id: 'cls-c',
          code: 'CANVAS-01',
          name: 'Canvas Class',
          sessions: [session],
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-c', classItem);
        attendanceRepo.setSessionData(
          'sess-canvas',
          createAttendanceResponseFixture(
            sessionId: 'sess-canvas',
            classId: 'cls-c',
            classCode: 'CANVAS-01',
            className: 'Canvas Class',
            sessionNumber: 1,
            title: session.title,
            students: [
              StudentAttendanceItemModel(
                studentId: 'st-c',
                userCode: 'HVC',
                fullName: 'Canvas Student',
                status: 'PRESENT',
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildSubject(size: const Size(764, 768)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.text('Điểm Danh & Sổ Đầu Bài'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // GROUP 6: ADVERSARIAL EDGE CASES & STRESS HARNESS
  // ===========================================================================
  group('6. Adversarial Edge Cases & Stress Scenarios', () {
    testWidgets(
      '6.1 Empty student roster: renders empty state without divide-by-zero crash',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-empty',
          classId: 'cls-empty',
          sessionNumber: 1,
          title: 'Empty Session',
        );
        final classItem = createClassFixture(
          id: 'cls-empty',
          code: 'EMP-01',
          name: 'Empty Class',
          sessions: [session],
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-empty', classItem);
        attendanceRepo.setSessionData(
          'sess-empty',
          createAttendanceResponseFixture(
            sessionId: 'sess-empty',
            classId: 'cls-empty',
            classCode: 'EMP-01',
            className: 'Empty Class',
            sessionNumber: 1,
            title: session.title,
            students: [],
          ),
        );

        await tester.pumpWidget(buildSubject());
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Chưa có dữ liệu học viên'), findsOneWidget);

        // Verify "Có mặt tất cả" button is disabled (students.isEmpty ? null : ...)
        final markAllBtn = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Có mặt tất cả'),
        );
        expect(markAllBtn.onPressed, isNull);
      },
    );

    testWidgets(
      '6.2 Extreme strings stress (100+ char name, unicode, multiline) does not crash or overflow',
      (tester) async {
        final session = createSessionFixture(
          id: 'sess-extreme',
          classId: 'cls-x',
          sessionNumber: 1,
          title: 'Chuyên đề nâng cao: Phân tích cú pháp tiếng Anh học thuật & ngữ pháp học thuật nâng cao cấp độ C1/C2 quốc tế',
          notes: '[Bài tập]: Viết bài luận 1500 từ về ảnh hưởng của trí tuệ nhân tạo (AI) đối với ngôn ngữ học hiện đại và giáo dục thế hệ tương lai.\n[Nhận xét]: Học viên có ý thức cao nhưng cần cẩn trọng tránh đạo văn.',
        );
        final classItem = createClassFixture(
          id: 'cls-x',
          code: 'EXTREME-01',
          name: 'Lớp Học Dài Tên Nhất Trung Tâm Ngoại Ngữ',
          sessions: [session],
        );

        final students = [
          StudentAttendanceItemModel(
            studentId: 'st-x1',
            userCode: 'HV-LONG-CODE-9999999999999999',
            fullName: 'Công Tằng Tôn Nữ Nguyễn Thị Long Lanh Ánh Tuyết Lóng Lánh Hoa Lệ Đệ Nhất Mỹ Nữ Sài Thành',
            phone: '+84 (028) 38.222.999 ext 1234567890',
            notes: 'Học viên xin phép đến muộn do kẹt xe nghiêm trọng trên cầu Sài Gòn và trời mưa to ngập nước.',
            status: 'LATE',
          ),
        ];

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-x', classItem);
        attendanceRepo.setSessionData(
          'sess-x',
          createAttendanceResponseFixture(
            sessionId: 'sess-x',
            classId: 'cls-x',
            classCode: 'EXTREME-01',
            className: 'Lớp Dài',
            sessionNumber: 1,
            title: session.title,
            students: students,
          ),
        );

        // Test on mobile 393x852
        setupScreenSize(tester, 393, 852);
        await tester.pumpWidget(buildSubject(size: const Size(393, 852)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Công Tằng Tôn Nữ'), findsOneWidget);

        // Test on desktop 1024x768
        setupScreenSize(tester, 1024, 768);
        await tester.pumpWidget(buildSubject(size: const Size(1024, 768)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6.3 Large Roster Stress: 30 students rendered and status updated smoothly',
      (tester) async {
        setupScreenSize(tester, 1024, 768);

        final session = createSessionFixture(
          id: 'sess-30',
          classId: 'cls-30',
          sessionNumber: 1,
          title: 'Big Roster',
        );
        final classItem = createClassFixture(
          id: 'cls-30',
          code: 'BIG-30',
          name: 'Big Class',
          sessions: [session],
        );

        final students = List.generate(
          30,
          (i) => StudentAttendanceItemModel(
            studentId: 'st-$i',
            userCode: 'HV${i.toString().padLeft(3, '0')}',
            fullName: 'Học Viên Số $i',
            status: i % 2 == 0 ? 'PRESENT' : 'ABSENT',
          ),
        );

        classesRepo.setMyClasses([classItem]);
        classesRepo.setClassDetail('cls-30', classItem);
        attendanceRepo.setSessionData(
          'sess-30',
          createAttendanceResponseFixture(
            sessionId: 'sess-30',
            classId: 'cls-30',
            classCode: 'BIG-30',
            className: 'Big Class',
            sessionNumber: 1,
            title: session.title,
            students: students,
          ),
        );

        await tester.pumpWidget(buildSubject(size: const Size(1024, 768)));
        classesBloc.add(const FetchMyClasses());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        // 15 present out of 30 = 50.0%
        expect(find.text('Tỷ lệ chuyên cần: 50.0%'), findsOneWidget);

        // Tap "Có mặt tất cả"
        await tester.tap(find.text('Có mặt tất cả'));
        await tester.pump();

        // All 30 should now be present -> 100.0%
        expect(find.text('Tỷ lệ chuyên cần: 100.0%'), findsOneWidget);
      },
    );
  });
}
