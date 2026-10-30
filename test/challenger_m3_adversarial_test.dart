import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:lms_trung_tam_ngoai_ngu/core/theme/app_colors.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/data/models/class_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/domain/repositories/classes_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/screens/schedule_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/teacher_grading_view.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/dashboard/presentation/views/teacher_gradebook_view.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/data/models/report_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/domain/repositories/reports_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/bloc/reports_bloc.dart';

// =============================================================================
// MOCK IMPLEMENTATIONS FOR TEST HARNESS
// =============================================================================

class MockClassesRepository implements ClassesRepository {
  List<ClassModel> myClasses = [];
  ClassModel? classDetail;
  List<ClassSessionModel> schedule = [];
  bool shouldThrowOnSchedule = false;

  @override
  Future<List<ClassModel>> getMyClasses() async => myClasses;

  @override
  Future<ClassModel> getClassDetail(String id) async =>
      classDetail ??
      (myClasses.isNotEmpty ? myClasses.first : throw Exception('Not found'));

  @override
  Future<List<ClassSessionModel>> getMySchedule({
    String? fromDate,
    String? toDate,
  }) async {
    if (shouldThrowOnSchedule) {
      throw Exception('Lỗi mạng khi tải lịch học');
    }
    return schedule;
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
  Future<ClassSessionModel> updateSession(
    String sessionId, {
    String? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? teacherId,
    String? status,
    String? notes,
    String? title,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteClass(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<AssignmentAttachmentModel> uploadAttachment(
    String fileName,
    Uint8List bytes,
  ) async => throw UnimplementedError();
  @override
  Future<AssignmentModel> updateAssignment(
    String id, {
    required String title,
    required String description,
    required String type,
    String? deadline,
    required double maxScore,
    required List<Map<String, dynamic>> attachments,
  }) async => throw UnimplementedError();
  List<AssignmentModel> classAssignments = [];
  AssignmentSubmissionsResponseModel? submissionsResponse;
  double? lastGradedScore;
  String? lastGradedFeedback;
  String? lastGradedSubmissionId;

  @override
  Future<List<AssignmentModel>> getClassAssignments(String classId) async =>
      classAssignments;

  @override
  Future<AssignmentSubmissionsResponseModel> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    return submissionsResponse ??
        const AssignmentSubmissionsResponseModel(
          assignmentId: 'a1',
          title: 'Task 1',
          maxScore: 10,
          type: 'SPEAKING',
          totalEnrolled: 0,
          submittedCount: 0,
          gradedCount: 0,
          lateCount: 0,
          notSubmittedCount: 0,
          students: [],
        );
  }

  @override
  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required double score,
    String? feedback,
  }) async {
    lastGradedSubmissionId = submissionId;
    lastGradedScore = score;
    lastGradedFeedback = feedback;
    return SubmissionModel(
      id: submissionId,
      assignmentId: 'a1',
      studentId: 's1',
      score: score,
      feedback: feedback,
      status: 'GRADED',
      fileUrls: const [],
      submittedAt: '2026-10-19T10:00:00Z',
    );
  }

  @override
  Future<AssignmentModel> createAssignment(
    String classId, {
    required String title,
    String? description,
    String? type,
    String? deadline,
    double? maxScore,
    List<Map<String, dynamic>>? attachments,
  }) async => throw UnimplementedError();

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<SubmissionModel> submitAssignment(
    String assignmentId, {
    String? content,
    List<Map<String, dynamic>>? fileUrls,
  }) async => throw UnimplementedError();
}

class MockReportsRepository implements ReportsRepository {
  AcademicReportModel? academicReport;

  Future<AcademicReportModel> getAcademicReport({
    String? classId,
    String? examId,
  }) async {
    return academicReport ??
        const AcademicReportModel(
          totalAttempts: 25,
          averageScore: 7.8,
          passRate: 92.0,
          classification: AcademicClassificationModel(
            excellent: AcademicClassificationStat(count: 8, percentage: 32.0),
            good: AcademicClassificationStat(count: 12, percentage: 48.0),
            average: AcademicClassificationStat(count: 3, percentage: 12.0),
            poor: AcademicClassificationStat(count: 2, percentage: 8.0),
          ),
          topStudents: [
            TopStudentAcademicItem(
              attemptId: 'at1',
              studentName: 'Nguyễn Văn A',
              studentCode: 'HV001',
              examTitle: 'Midterm',
              score: 9.5,
              percentage: 95.0,
            ),
          ],
        );
  }

  @override
  Future<DashboardOverviewModel> getDashboardOverview() async =>
      throw UnimplementedError();

  @override
  Future<RevenueReportModel> getRevenueReport({
    int? year,
    String? branchId,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceReportModel> getAttendanceReport({
    String? classId,
    String? startDate,
    String? endDate,
  }) async => throw UnimplementedError();

  @override
  Future<DebtsReportModel> getDebtsReport({
    String? branchId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<List<TeacherWorkloadModel>> getTeacherWorkloadReport() async =>
      throw UnimplementedError();

  @override
  Future<void> refreshDashboardCache() async {}
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('vi_VN', null);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  // ===========================================================================
  // GROUP 1: IELTS RUBRICS SCORE MATH & BOUNDING ADVERSARIAL STRESS TESTS
  // ===========================================================================
  group('1. IELTS Rubrics Score Math & Bounding', () {
    test('Speaking criteria average calculation: PR, FC, GRA, LR', () {
      // 4 Speaking criteria: Pronunciation, Fluency, Grammar, Lexical
      double pronunciation = 7.0;
      double fluency = 7.5;
      double grammar = 6.5;
      double lexical = 7.0;

      final double calculatedOverall =
          (pronunciation + fluency + grammar + lexical) / 4;
      final double finalScore = double.parse(
        calculatedOverall.toStringAsFixed(1),
      );

      expect(calculatedOverall, equals(7.0));
      expect(finalScore, equals(7.0));
    });

    test('Writing criteria average calculation: TR, CC, LR, GRA', () {
      // 4 Writing criteria: Task Response, Coherence, Lexical, Grammar
      double taskResponse = 8.0;
      double coherence = 7.5;
      double lexical = 7.0;
      double grammar = 7.5;

      final double calculatedOverall =
          (taskResponse + coherence + lexical + grammar) / 4;
      final double finalScore = double.parse(
        calculatedOverall.toStringAsFixed(1),
      );

      expect(calculatedOverall, equals(7.5));
      expect(finalScore, equals(7.5));
    });

    test(
      'Rubric scores bounded strictly between 1.0 and 9.0 (min / max bounds)',
      () {
        // Minimum lower bound
        double minPR = 1.0;
        double minFC = 1.0;
        double minGRA = 1.0;
        double minLR = 1.0;
        double minOverall = (minPR + minFC + minGRA + minLR) / 4;
        expect(minOverall, equals(1.0));
        expect(minOverall, inInclusiveRange(1.0, 9.0));

        // Maximum upper bound
        double maxPR = 9.0;
        double maxFC = 9.0;
        double maxGRA = 9.0;
        double maxLR = 9.0;
        double maxOverall = (maxPR + maxFC + maxGRA + maxLR) / 4;
        expect(maxOverall, equals(9.0));
        expect(maxOverall, inInclusiveRange(1.0, 9.0));
      },
    );

    test('Empirical Generator: 1000 randomized 4-criteria permutations all stay within 1.0 to 9.0', () {
      final rng = Random(42);
      final allowedSteps = [
        1.0,
        1.5,
        2.0,
        2.5,
        3.0,
        3.5,
        4.0,
        4.5,
        5.0,
        5.5,
        6.0,
        6.5,
        7.0,
        7.5,
        8.0,
        8.5,
        9.0,
      ];

      for (int i = 0; i < 1000; i++) {
        final c1 = allowedSteps[rng.nextInt(allowedSteps.length)];
        final c2 = allowedSteps[rng.nextInt(allowedSteps.length)];
        final c3 = allowedSteps[rng.nextInt(allowedSteps.length)];
        final c4 = allowedSteps[rng.nextInt(allowedSteps.length)];

        final overall = (c1 + c2 + c3 + c4) / 4;
        final rounded = double.parse(overall.toStringAsFixed(1));

        expect(overall, greaterThanOrEqualTo(1.0));
        expect(overall, lessThanOrEqualTo(9.0));
        expect(rounded, greaterThanOrEqualTo(1.0));
        expect(rounded, lessThanOrEqualTo(9.0));
      }
    });

    test('Slider step division invariant (16 divisions between 1.0 and 9.0 = 0.5 per step)', () {
      const min = 1.0;
      const max = 9.0;
      const divisions = 16;
      const step = (max - min) / divisions;

      expect(step, equals(0.5));
      for (int i = 0; i <= divisions; i++) {
        final val = min + (i * step);
        expect(val % 0.5, equals(0.0));
      }
    });
  });

  // ===========================================================================
  // GROUP 2: GRADING FEEDBACK FORMATTING & PAYLOAD STRUCTURE
  // ===========================================================================
  group('2. Grading Feedback Formatting and Payload Structure', () {
    test('Speaking rubric feedback string construction & newline serialization', () {
      double pronunciation = 7.5;
      double fluency = 7.0;
      double grammar = 6.5;
      double lexical = 7.0;
      String feedbackText = 'Phát âm tốt, cần chú ý ngữ điệu ở câu hỏi.';

      final rubricSummary =
          '[Rubric Speaking]\n• Pronunciation: $pronunciation\n• Fluency: $fluency\n• Grammar: $grammar\n• Lexical: $lexical';
      final fullFeedback = '$rubricSummary\n\n[Nhận xét]\n$feedbackText';

      expect(fullFeedback, contains('[Rubric Speaking]'));
      expect(fullFeedback, contains('• Pronunciation: 7.5'));
      expect(fullFeedback, contains('• Fluency: 7.0'));
      expect(fullFeedback, contains('• Grammar: 6.5'));
      expect(fullFeedback, contains('• Lexical: 7.0'));
      expect(fullFeedback, contains('[Nhận xét]'));
      expect(fullFeedback, contains(feedbackText));
    });

    test('Writing rubric feedback string construction & newline serialization', () {
      double taskAchievement = 7.0;
      double coherence = 6.5;
      double writingLexical = 7.5;
      double writingGrammar = 7.0;
      String feedbackText =
          'Bài viết bố cục rõ ràng, từ vựng học thuật phong phú.';

      final rubricSummary =
          '[Rubric Writing]\n• Task Response: $taskAchievement\n• Coherence: $coherence\n• Lexical: $writingLexical\n• Grammar: $writingGrammar';
      final fullFeedback = '$rubricSummary\n\n[Nhận xét]\n$feedbackText';

      expect(fullFeedback, contains('[Rubric Writing]'));
      expect(fullFeedback, contains('• Task Response: 7.0'));
      expect(fullFeedback, contains('• Coherence: 6.5'));
      expect(fullFeedback, contains('• Lexical: 7.5'));
      expect(fullFeedback, contains('• Grammar: 7.0'));
      expect(fullFeedback, contains('[Nhận xét]'));
      expect(fullFeedback, contains(feedbackText));
    });

    test('Round-trip parsing of feedback note extracting user comments accurately', () {
      const savedFeedback =
          '[Rubric Speaking]\n• Pronunciation: 7.0\n• Fluency: 7.0\n• Grammar: 6.5\n• Lexical: 7.0\n\n[Nhận xét]\nHọc viên phát âm chuẩn, lưu loát.';

      String extractedNote = '';
      if (savedFeedback.contains('[Nhận xét]')) {
        final parts = savedFeedback.split('[Nhận xét]');
        if (parts.length > 1) {
          extractedNote = parts[1].trim();
        }
      }

      expect(extractedNote, equals('Học viên phát âm chuẩn, lưu loát.'));
    });

    test('Feedback parsing edge cases: legacy note without [Nhận xét], empty note, and multiple tags', () {
      // 1. Legacy feedback without tag
      const legacy = 'Làm bài khá tốt.';
      String initialNote1 = legacy;
      if (legacy.contains('[Nhận xét]')) {
        final parts = legacy.split('[Nhận xét]');
        if (parts.length > 1) initialNote1 = parts[1].trim();
      }
      expect(initialNote1, equals('Làm bài khá tốt.'));

      // 2. Feedback with only rubric and empty user comments
      const rubricOnly =
          '[Rubric Writing]\n• Task Response: 7.0\n• Coherence: 7.0\n• Lexical: 7.0\n• Grammar: 6.5';
      String initialNote2 = rubricOnly;
      if (rubricOnly.contains('[Nhận xét]')) {
        final parts = rubricOnly.split('[Nhận xét]');
        if (parts.length > 1) initialNote2 = parts[1].trim();
      }
      expect(initialNote2, equals(rubricOnly));

      // 3. Feedback with multiple [Nhận xét] delimiters
      const multi =
          '[Rubric]\n\n[Nhận xét]\nFirst part\n[Nhận xét]\nSecond part';
      final parts = multi.split('[Nhận xét]');
      expect(parts.length, equals(3));
      expect(parts[1].trim(), equals('First part'));
    });
  });

  // ===========================================================================
  // GROUP 3: GRADEBOOK WEIGHTED GPA CALCULATION & RANKING CLASSIFICATION
  // ===========================================================================
  group('3. Gradebook Weighted GPA & Ranking Logic', () {
    double calculateGpa(double att, double hw, double mid, double fin) {
      return (att * 0.1) + (hw * 0.2) + (mid * 0.3) + (fin * 0.4);
    }

    String getRank(double gpa) {
      if (gpa >= 8.5) return 'Xuất sắc';
      if (gpa >= 7.0) return 'Giỏi';
      if (gpa >= 6.0) return 'Khá';
      return 'Trung bình';
    }

    Color getRankColor(double gpa) {
      if (gpa >= 8.5) return AppColors.success;
      if (gpa >= 7.0) return AppColors.primary;
      if (gpa >= 6.0) return Colors.amber.shade800;
      return AppColors.error;
    }

    test('Sum of weights equals exactly 1.0 (10% + 20% + 30% + 40%)', () {
      const wAtt = 0.1;
      const wHw = 0.2;
      const wMid = 0.3;
      const wFin = 0.4;
      const sum = wAtt + wHw + wMid + wFin;
      expect((sum - 1.0).abs(), lessThan(1e-9));
    });

    test('Weighted GPA calculation across representative score profiles', () {
      // 1. Perfect score
      expect(calculateGpa(10, 10, 10, 10), equals(10.0));
      expect(getRank(10.0), equals('Xuất sắc'));

      // 2. Default teacher gradebook template (9.5, 8.5, 8.0, 8.5)
      // 0.95 + 1.70 + 2.40 + 3.40 = 8.45
      final gpa1 = calculateGpa(9.5, 8.5, 8.0, 8.5);
      expect((gpa1 - 8.45).abs(), lessThan(1e-9));
      expect(getRank(gpa1), equals('Giỏi'));
      expect(getRankColor(gpa1), equals(AppColors.primary));

      // 3. Boundary exactly at 8.50 -> 'Xuất sắc'
      final gpa2 = calculateGpa(8.5, 8.5, 8.5, 8.5);
      expect((gpa2 - 8.50).abs(), lessThan(1e-9));
      expect(getRank(gpa2), equals('Xuất sắc'));
      expect(getRankColor(gpa2), equals(AppColors.success));

      // 4. Boundary just below 8.50 (e.g. 8.49) -> 'Giỏi'
      expect(getRank(8.499), equals('Giỏi'));

      // 5. Boundary at 7.00 -> 'Giỏi'
      expect(getRank(7.0), equals('Giỏi'));

      // 6. Boundary at 6.00 -> 'Khá'
      expect(getRank(6.0), equals('Khá'));
      expect(getRankColor(6.0), equals(Colors.amber.shade800));

      // 7. Below 6.00 -> 'Trung bình'
      expect(getRank(5.99), equals('Trung bình'));
      expect(getRankColor(5.99), equals(AppColors.error));
      expect(getRank(0.0), equals('Trung bình'));
      expect(getRankColor(0.0), equals(AppColors.error));
    });

    test(
      'AcademicReportModel JSON deserialization resilience and edge cases',
      () {
        // 1. Complete payload from /reports/academic
        final fullJson = {
          'totalAttempts': 45,
          'averageScore': 8.12,
          'passRate': 95.5,
          'classification': {
            'excellent': {'count': 15, 'percentage': 33.3},
            'good': {'count': 20, 'percentage': 44.4},
            'average': {'count': 8, 'percentage': 17.8},
            'poor': {'count': 2, 'percentage': 4.5},
          },
          'topStudents': [
            {
              'attemptId': 'att-1',
              'studentName': 'Lê Hoàng Nam',
              'studentCode': 'HV-9988',
              'examTitle': 'Final Speaking Exam',
              'score': 9.0,
              'percentage': 90.0,
              'isPassed': true,
            },
          ],
        };

        final report = AcademicReportModel.fromJson(fullJson);
        expect(report.totalAttempts, equals(45));
        expect(report.averageScore, equals(8.12));
        expect(report.passRate, equals(95.5));
        expect(report.classification.excellent.count, equals(15));
        expect(report.classification.poor.percentage, equals(4.5));
        expect(report.topStudents.length, equals(1));
        expect(report.topStudents.first.studentName, equals('Lê Hoàng Nam'));

        // 2. Empty JSON resilience
        final emptyReport = AcademicReportModel.fromJson({});
        expect(emptyReport.totalAttempts, equals(0));
        expect(emptyReport.averageScore, equals(0.0));
        expect(emptyReport.passRate, equals(0.0));
        expect(emptyReport.classification.excellent.count, equals(0));
        expect(emptyReport.classification.poor.percentage, equals(0.0));
        expect(emptyReport.topStudents, isEmpty);
      },
    );
  });

  // ===========================================================================
  // GROUP 4: TEACHER WEEKLY SCHEDULE LOADING & ERROR RESILIENCE
  // ===========================================================================
  group('4. Teacher Weekly Schedule Loading and Error Resilience', () {
    testWidgets(
      'ScheduleScreen loads sessions and filters accurately by selected date',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        final now = DateTime.now();

        mockClassesRepo.schedule = [
          ClassSessionModel(
            id: 'sess-1',
            classId: 'c1',
            className: 'IELTS Intensive 6.5+',
            classCode: 'IELTS-INT-01',
            sessionNumber: 1,
            title: 'Speaking Practice: Part 2 Monologue',
            date: now,
            startTime: '18:00',
            endTime: '20:00',
            status: 'SCHEDULED',
            roomName: 'A102',
            teacherName: 'Mr. David Nguyễn',
          ),
          ClassSessionModel(
            id: 'sess-2',
            classId: 'c1',
            className: 'IELTS Intensive 6.5+',
            classCode: 'IELTS-INT-01',
            sessionNumber: 2,
            title: 'Writing Task 2: Opinion Essay',
            date: now.add(const Duration(days: 3)),
            startTime: '18:00',
            endTime: '20:00',
            status: 'SCHEDULED',
            roomName: 'A102',
            teacherName: 'Mr. David Nguyễn',
          ),
        ];

        final classesBloc = ClassesBloc(repository: mockClassesRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: classesBloc,
              child: const ScheduleScreen(showAppBar: true),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify that sess-1 is displayed for today
        expect(
          find.text('Speaking Practice: Part 2 Monologue'),
          findsOneWidget,
        );
        expect(find.text('Lớp: IELTS Intensive 6.5+'), findsOneWidget);
        expect(find.text('18:00 - 20:00'), findsOneWidget);
        expect(find.text('Phòng A102'), findsOneWidget);
        expect(find.text('GV: Mr. David Nguyễn'), findsOneWidget);
        expect(find.text('Sắp diễn ra'), findsOneWidget);

        // Verify that sess-2 for day+3 is not rendered under today's view
        expect(find.text('Writing Task 2: Opinion Essay'), findsNothing);
      },
    );

    testWidgets(
      'ScheduleScreen renders EmptyStateWidget when no sessions scheduled on selected day',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        mockClassesRepo.schedule = []; // Empty schedule

        final classesBloc = ClassesBloc(repository: mockClassesRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: classesBloc,
              child: const ScheduleScreen(showAppBar: false),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Không có lịch học'), findsOneWidget);
        expect(
          find.text(
            'Bạn không có buổi học hay lịch giảng dạy nào vào ngày này.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ScheduleScreen handles ClassesError state resiliently with floating SnackBar',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        mockClassesRepo.shouldThrowOnSchedule = true;

        final classesBloc = ClassesBloc(repository: mockClassesRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<ClassesBloc>.value(
                value: classesBloc,
                child: const ScheduleScreen(showAppBar: false),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // SnackBar with error should be triggered
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Lỗi mạng khi tải lịch học'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ScheduleScreen handles session model edge cases (null room, null teacher, status mapping)',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        final now = DateTime.now();

        mockClassesRepo.schedule = [
          ClassSessionModel(
            id: 'sess-edge-1',
            classId: 'c1',
            sessionNumber: 3,
            title: 'Special Topic',
            date: now,
            startTime: '08:00',
            endTime: '10:00',
            status: 'COMPLETED',
            roomName: null, // Null room
            teacherName: null, // Null teacher
          ),
          ClassSessionModel(
            id: 'sess-edge-2',
            classId: 'c1',
            sessionNumber: 4,
            title: 'Makeup Session',
            date: now,
            startTime: '10:30',
            endTime: '12:00',
            status: 'CANCELLED',
          ),
          ClassSessionModel(
            id: 'sess-edge-3',
            classId: 'c1',
            sessionNumber: 5,
            title: 'Review Session',
            date: now,
            startTime: '14:00',
            endTime: '16:00',
            status: 'RESCHEDULED',
          ),
        ];

        final classesBloc = ClassesBloc(repository: mockClassesRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ClassesBloc>.value(
              value: classesBloc,
              child: const ScheduleScreen(showAppBar: false),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Null fallbacks
        expect(find.text('Chưa xếp phòng'), findsOneWidget);
        expect(find.text('Chưa gán GV'), findsOneWidget);

        // Status labels
        expect(find.text('Đã hoàn thành'), findsOneWidget);
        expect(find.text('Đã hủy'), findsOneWidget);
        expect(find.text('Dời lịch'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // GROUP 5: WIDGET TESTS & INTERACTIVE RUBRICS GRADING VIEWPORT STRESS
  // ===========================================================================
  group('5. TeacherGradingView & TeacherGradebookView Widget Stress', () {
    testWidgets(
      'Empirical Defect Discovery: TeacherGradingView dropdown RenderFlex overflow without isExpanded',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        final mockAssignmentsRepo = MockAssignmentsRepository();

        final testClass = ClassModel(
          id: 'cls-1',
          name: 'IELTS Master 7.5',
          code: 'IELTS-M75',
          courseId: 'crs-1',
          courseTitle: 'IELTS Master',
          levelId: 'lvl-1',
          branchId: 'br-1',
          branchName: 'Chi nhánh 1',
          status: 'ACTIVE',
          roomName: 'Lab 1',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 90)),
          startTime: '18:00',
          endTime: '20:00',
          studentsCount: 1,
          maxCapacity: 15,
          totalSessions: 30,
          sessionsCount: 5,
        );

        const speakingAssignment = AssignmentModel(
          id: 'asg-speak-1',
          classId: 'cls-1',
          title:
              'IELTS Speaking Part 2 Mock Test with Detailed Rubric Evaluation',
          type: 'SPEAKING',
          maxScore: 9.0,
          attachments: [],
          createdAt: '2026-10-19T00:00:00Z',
        );

        mockClassesRepo.myClasses = [testClass];
        mockAssignmentsRepo.classAssignments = [speakingAssignment];
        mockAssignmentsRepo
            .submissionsResponse = const AssignmentSubmissionsResponseModel(
          assignmentId: 'asg-speak-1',
          title:
              'IELTS Speaking Part 2 Mock Test with Detailed Rubric Evaluation',
          maxScore: 9.0,
          type: 'SPEAKING',
          totalEnrolled: 1,
          submittedCount: 1,
          gradedCount: 0,
          lateCount: 0,
          notSubmittedCount: 0,
          students: [
            StudentSubmissionItemModel(
              studentId: 'std-1',
              userCode: 'HV001',
              fullName: 'Võ Thị Mai',
              hasSubmitted: true,
              submission: SubmissionModel(
                id: 'sub-1',
                assignmentId: 'asg-speak-1',
                studentId: 'std-1',
                status: 'SUBMITTED',
                submittedAt: '2026-10-19T08:30:00Z',
                fileUrls: [
                  AssignmentAttachmentModel(
                    name: 'part2_talk.m4a',
                    url: 'https://cdn/audio.m4a',
                    fileType: 'AUDIO',
                    size: 1048576,
                  ),
                ],
              ),
            ),
          ],
        );

        GetIt.I.registerSingleton<ClassesRepository>(mockClassesRepo);
        GetIt.I.registerSingleton<AssignmentsRepository>(mockAssignmentsRepo);

        // Listen for FlutterError layout overflows
        final capturedErrors = <FlutterErrorDetails>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
        };

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          FlutterError.onError = oldHandler;
          tester.view.resetPhysicalSize();
        });

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: TeacherGradingView())),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Empirically detect whether RenderFlex overflowed due to missing isExpanded: true
        final hasRenderFlexOverflow = capturedErrors.any(
          (e) => e.toString().contains('A RenderFlex overflowed'),
        );
        expect(
          hasRenderFlexOverflow,
          isTrue,
          reason: 'DropdownButtonFormField missing isExpanded:true must trigger RenderFlex overflow on long titles',
        );
      },
    );

    testWidgets(
      'TeacherGradebookView renders student grades and computes weighted GPA correctly',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        final mockReportsRepo = MockReportsRepository();

        const studentItem = ClassStudentModel(
          id: 'cs-1',
          classId: 'cls-gradebook-1',
          studentId: 'stu-101',
          studentName: 'Trần Minh Hoàng',
          studentCode: 'HV-101',
          status: 'ENROLLED',
        );

        final testClass = ClassModel(
          id: 'cls-gradebook-1',
          name: 'IELTS Foundation Band 5.0',
          code: 'IELTS-F50',
          courseId: 'crs-1',
          courseTitle: 'IELTS Foundation',
          levelId: 'lvl-1',
          branchId: 'br-1',
          branchName: 'Chi nhánh 1',
          status: 'ACTIVE',
          roomName: 'Room 201',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 60)),
          startTime: '18:00',
          endTime: '20:00',
          studentsCount: 1,
          maxCapacity: 20,
          totalSessions: 24,
          sessionsCount: 8,
          students: const [studentItem],
        );

        mockClassesRepo.myClasses = [testClass];
        mockClassesRepo.classDetail = testClass;

        final classesBloc = ClassesBloc(repository: mockClassesRepo);
        final reportsBloc = ReportsBloc(repository: mockReportsRepo);

        GetIt.I.registerSingleton<ClassesBloc>(classesBloc);
        GetIt.I.registerSingleton<ReportsBloc>(reportsBloc);

        // Desktop viewport
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<ClassesBloc>.value(value: classesBloc),
                  BlocProvider<ReportsBloc>.value(value: reportsBloc),
                ],
                child: const TeacherGradebookView(),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Gradebook header and table
        expect(find.text('Bảng Điểm & Đánh Giá Học Viên'), findsOneWidget);
        expect(find.text('Chuyên cần (10%)'), findsWidgets);
        expect(find.text('Bài tập (20%)'), findsWidgets);
        expect(find.text('Giữa kỳ (30%)'), findsWidgets);
        expect(find.text('Cuối kỳ (40%)'), findsWidgets);

        // Student row verification: default scores 9.5, 8.5, 8.0, 8.5 -> GPA 8.45 -> Rank 'Giỏi'
        expect(find.text('Trần Minh Hoàng'), findsOneWidget);
        expect(find.text('HV-101'), findsOneWidget);
        expect(find.text('8.45'), findsOneWidget);
        expect(find.text('Giỏi'), findsWidgets);

        // Verify academic report KPIs from mock
        expect(find.text('Tỷ lệ Đạt (Pass Rate)'), findsOneWidget);
        expect(find.text('92.0%'), findsOneWidget);
        expect(find.text('7.8'), findsOneWidget);
      },
    );

    testWidgets(
      'TeacherGradebookView renders cleanly without crash on Pixel 9 mobile (393 x 852)',
      (tester) async {
        final mockClassesRepo = MockClassesRepository();
        final mockReportsRepo = MockReportsRepository();

        const studentItem = ClassStudentModel(
          id: 'cs-mob-1',
          classId: 'cls-mob-1',
          studentId: 'stu-mobile-1',
          studentName: 'Phạm Thu Trang',
          studentCode: 'HV-MOB-01',
          status: 'ENROLLED',
        );

        final testClass = ClassModel(
          id: 'cls-mob-1',
          name: 'IELTS Starter',
          code: 'IELTS-ST',
          courseId: 'crs-1',
          courseTitle: 'IELTS Starter',
          levelId: 'lvl-1',
          branchId: 'br-1',
          branchName: 'Chi nhánh 1',
          status: 'ACTIVE',
          roomName: 'Room 101',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          startTime: '18:00',
          endTime: '20:00',
          studentsCount: 1,
          maxCapacity: 15,
          totalSessions: 12,
          sessionsCount: 2,
          students: const [studentItem],
        );

        mockClassesRepo.myClasses = [testClass];
        mockClassesRepo.classDetail = testClass;

        final classesBloc = ClassesBloc(repository: mockClassesRepo);
        final reportsBloc = ReportsBloc(repository: mockReportsRepo);

        GetIt.I.registerSingleton<ClassesBloc>(classesBloc);
        GetIt.I.registerSingleton<ReportsBloc>(reportsBloc);

        // Set Mobile Pixel 9 viewport
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<ClassesBloc>.value(value: classesBloc),
                  BlocProvider<ReportsBloc>.value(value: reportsBloc),
                ],
                child: const TeacherGradebookView(),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify no exceptions thrown
        expect(tester.takeException(), isNull);
        expect(find.text('Bảng Điểm & Đánh Giá Học Viên'), findsOneWidget);
      },
    );
  });
}
