import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/di/injection.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/student_gradebook_view.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';

class _Classes implements ClassesRepository {
  @override
  Future<List<ClassModel>> getMyClasses() async => [
    const ClassModel(
      id: 'class-1',
      code: 'IELTS-01',
      name: 'IELTS Foundation',
      courseId: 'course-1',
      levelId: 'level-1',
      branchId: 'branch-1',
      startTime: '18:00',
      endTime: '19:30',
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Assignments implements AssignmentsRepository {
  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async => [
    AssignmentModel.fromJson({
      'id': 'a-1',
      'classId': classId,
      'title': 'Writing Task 1',
      'type': 'WRITING',
      'maxScore': 10,
      'createdAt': '2026-10-27',
      'mySubmission': {
        'id': 's-1',
        'assignmentId': 'a-1',
        'studentId': 'student-1',
        'status': 'GRADED',
        'score': 8,
        'feedback': 'Viết tốt',
        'gradedAt': '2026-10-27',
        'fileUrls': [],
      },
    }),
    AssignmentModel.fromJson({
      'id': 'a-2',
      'classId': classId,
      'title': 'Điểm chưa công bố',
      'type': 'HOMEWORK',
      'maxScore': 10,
      'createdAt': '2026-10-27',
      'mySubmission': {
        'id': 's-2',
        'assignmentId': 'a-2',
        'studentId': 'student-1',
        'status': 'GRADED_PENDING',
        'score': 10,
        'fileUrls': [],
      },
    }),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Exams implements ExamsRepository {
  @override
  Future<List<ExamAttemptModel>> getMyExamResults() async => [
    ExamAttemptModel.fromJson({
      'id': 'attempt-1',
      'examId': 'exam-1',
      'studentId': 'student-1',
      'status': 'GRADED',
      'score': 9,
      'maxScore': 10,
      'startedAt': '2026-10-26',
      'submittedAt': '2026-10-26',
    }),
  ];
  @override
  Future<List<ExamModel>> getExams({String? classId, String? status}) async => [
    ExamModel.fromJson({
      'id': 'exam-1',
      'title': 'Kiểm tra giữa kỳ',
      'classId': 'class-1',
      'status': 'PUBLISHED',
    }),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('bảng điểm thật thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      getIt.registerSingleton<ClassesRepository>(_Classes());
      getIt.registerSingleton<AssignmentsRepository>(_Assignments());
      getIt.registerSingleton<ExamsRepository>(_Exams());
      addTearDown(() async => getIt.reset());
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentGradebookView())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Writing Task 1'), findsOneWidget);
      expect(find.text('Kiểm tra giữa kỳ'), findsOneWidget);
      expect(find.text('Điểm chưa công bố'), findsNothing);
      expect(find.text('8.5 / 10'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            width < 600
                ? 'student-gradebook-mobile'
                : 'student-gradebook-desktop',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
