import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/exam_result_screen.dart';

class _ResultsRepository extends Fake implements ExamsRepository {
  _ResultsRepository({this.attempts = const [], this.fail = false});

  final List<ExamAttemptModel> attempts;
  final bool fail;

  @override
  Future<ExamResultsResponseModel> getExamResults(String examId) async {
    if (fail) throw StateError('Không tải được kết quả');
    return ExamResultsResponseModel(
      exam: const ExamModel(
        id: 'exam-1',
        title: 'Kiểm tra cuối khóa với tiêu đề dài để kiểm tra bố cục Mobile',
        className: 'Lớp IELTS Foundation',
        durationMinutes: 60,
        passPercentage: 60,
        totalPoints: 10,
        shuffleQuestions: false,
        maxAttempts: 2,
        status: 'PUBLISHED',
      ),
      summary: ExamResultsSummaryModel(
        totalAttempts: attempts.length,
        gradedCount: attempts.where((a) => a.score != null).length,
        passedCount: attempts.where((a) => a.isPassed == true).length,
        passRate: 50,
        averageScore: 7.5,
      ),
      attempts: attempts,
    );
  }
}

ExamAttemptModel _attempt(String name, {bool? passed, double? score}) =>
    ExamAttemptModel(
      id: name,
      examId: 'exam-1',
      studentId: name,
      studentName: name,
      studentCode: 'HV-01',
      attemptNumber: 1,
      startedAt: '2026-10-28',
      score: score,
      maxScore: 10,
      isPassed: passed,
      status: score == null ? 'SUBMITTED' : 'GRADED',
    );

Widget _app(_ResultsRepository repository) => MaterialApp(
  home: BlocProvider(
    create: (_) => ExamsBloc(repository: repository),
    child: const ExamResultScreen(examId: 'exam-1'),
  ),
);

void main() {
  final attempts = [
    _attempt('Nguyễn Minh Anh', passed: true, score: 8.5),
    _attempt('Trần Gia Bảo', passed: false, score: 4),
    _attempt('Lê Khánh Chi'),
  ];

  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('teacher exam results $width px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_ResultsRepository(attempts: attempts)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kiểm tra cuối khóa'), findsOneWidget);
      if (width < 1024) {
        expect(
          find.byKey(const ValueKey('teacher-exam-results-mobile')),
          findsOneWidget,
        );
        expect(find.text('Tổng quan kết quả'), findsOneWidget);
      } else {
        expect(
          find.byKey(const ValueKey('teacher-exam-results-mobile')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile filters results without losing backend data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_ResultsRepository(attempts: attempts)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đạt').first);
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('Trần Gia Bảo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile empty and API error states', (tester) async {
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_ResultsRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có kết quả phù hợp với bộ lọc.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(_ResultsRepository(fail: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được kết quả'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
