import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/teacher_class_workflow_view.dart';

class _ClassesRepository implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [
    ClassModel.fromJson({
      'id': 'class-1',
      'code': 'IELTS-01',
      'name': 'Lớp IELTS Foundation – Nhóm A với tên lớp rất dài',
      'courseId': 'course-1',
      'levelId': 'level-1',
      'branchId': 'branch-1',
      'startTime': '16:00',
      'endTime': '17:30',
    }),
  ];

  @override
  Future<List<ClassSessionModel>> getClassSessions(String classId) async => [
    ClassSessionModel(
      id: 'session-1',
      classId: classId,
      title: 'Buổi 1: thực hành',
      date: DateTime(2026, 10, 26),
      startTime: '16:00',
      endTime: '17:30',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AssignmentsRepository implements AssignmentsRepository {
  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async => [
    AssignmentModel(
      id: 'assignment-1',
      classId: classId,
      title: 'Writing Task 1',
      type: 'WRITING',
      maxScore: 10,
      attachments: const [],
      createdAt: '2026-10-26T00:00:00.000Z',
      totalSubmissions: 6,
      gradedCount: 2,
    ),
  ];

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async => AssignmentSubmissionsResponseModel(
    assignmentId: assignmentId,
    title: 'Writing Task 1',
    maxScore: 10,
    type: 'WRITING',
    totalEnrolled: 1,
    submittedCount: 1,
    gradedCount: 1,
    lateCount: 0,
    notSubmittedCount: 0,
    students: const [
      StudentSubmissionItemModel(
        studentId: 'student-1',
        userCode: 'HV-01',
        fullName: 'Nguyễn Minh Anh',
        hasSubmitted: true,
        submission: SubmissionModel(
          id: 'submission-1',
          assignmentId: 'assignment-1',
          studentId: 'student-1',
          fileUrls: [],
          submittedAt: '2026-10-26T00:00:00Z',
          status: 'GRADED',
          score: 8.5,
          feedback: 'Bố cục tốt',
        ),
      ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    getIt.registerSingleton<ClassesRepository>(_ClassesRepository());
    getIt.registerSingleton<AssignmentsRepository>(_AssignmentsRepository());
  });
  tearDown(() async => getIt.reset());

  testWidgets('giảng viên thấy buổi học thật để mở điểm danh', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherClassWorkflowView(mode: TeacherWorkflowMode.attendance),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Lớp IELTS Foundation'), findsOneWidget);
    expect(find.text('Buổi 1: thực hành'), findsOneWidget);
  });

  testWidgets('giảng viên thấy số bài đã chấm từ API', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherClassWorkflowView(mode: TeacherWorkflowMode.assignments),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Writing Task 1'), findsOneWidget);
    expect(find.textContaining('2/6 bài đã chấm'), findsOneWidget);
    expect(find.text('Giao bài tập'), findsOneWidget);
  });

  testWidgets('danh sách bài tập không tràn trên màn hình điện thoại', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherClassWorkflowView(mode: TeacherWorkflowMode.assignments),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Writing Task 1'), findsOneWidget);
  });

  testWidgets('kết quả chỉ hiển thị bài đã chấm và không có nút giao bài', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherClassWorkflowView(mode: TeacherWorkflowMode.results),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('8.5/10'), findsOneWidget);
    expect(find.text('Giao bài tập'), findsNothing);
  });
}
