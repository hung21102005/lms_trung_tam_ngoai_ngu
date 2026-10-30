import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/exam_list_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/my_exam_results_screen.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/take_exam_screen.dart';

class _ExamsRepository implements ExamsRepository {
  @override
  Future<Map<String, dynamic>> startExam(String examId) async => {
    'exam': ExamModel(
      id: examId,
      title: 'IELTS Reading',
      durationMinutes: 45,
      passPercentage: 50,
      totalPoints: 10,
      shuffleQuestions: false,
      maxAttempts: 2,
      status: 'PUBLISHED',
      examQuestions: const [
        ExamQuestionModel(
          id: 'eq1',
          examId: 'exam-1',
          questionId: 'q1',
          orderIndex: 0,
          points: 5,
          question: QuestionModel(
            id: 'q1',
            type: 'MULTIPLE_CHOICE',
            prompt: 'Chọn đáp án đúng',
            options: [QuestionOptionModel(id: 'A', text: 'Answer A')],
          ),
        ),
        ExamQuestionModel(
          id: 'eq2',
          examId: 'exam-1',
          questionId: 'q2',
          orderIndex: 1,
          points: 5,
          question: QuestionModel(
            id: 'q2',
            type: 'ESSAY',
            prompt: 'Viết câu trả lời',
          ),
        ),
      ],
    ),
    'attempt': ExamAttemptModel(
      id: 'attempt-new',
      examId: examId,
      studentId: 'student-1',
      attemptNumber: 1,
      startedAt: DateTime.now().toIso8601String(),
      maxScore: 10,
      status: 'IN_PROGRESS',
    ),
  };

  @override
  Future<void> saveExamAnswers(
    String attemptId,
    List<Map<String, dynamic>> answers,
  ) async {}

  @override
  Future<List<ExamModel>> getExams({String? classId, String? status}) async => [
    const ExamModel(
      id: 'exam-1',
      title: 'IELTS Reading',
      durationMinutes: 45,
      passPercentage: 50,
      totalPoints: 10,
      shuffleQuestions: false,
      maxAttempts: 2,
      status: 'PUBLISHED',
      questionsCount: 10,
    ),
    const ExamModel(
      id: 'exam-2',
      title: 'Bản nháp nội bộ',
      durationMinutes: 45,
      passPercentage: 50,
      totalPoints: 10,
      shuffleQuestions: false,
      maxAttempts: 1,
      status: 'DRAFT',
    ),
  ];

  @override
  Future<List<ExamAttemptModel>> getMyExamResults() async => [
    ExamAttemptModel.fromJson({
      'id': 'attempt-1',
      'examId': 'exam-1',
      'studentId': 'student-1',
      'attemptNumber': 1,
      'startedAt': '2026-10-28',
      'score': 8,
      'maxScore': 10,
      'status': 'GRADED',
      'exam': {
        'title': 'IELTS Reading',
        'class': {'name': 'IELTS Foundation'},
      },
    }),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('làm bài kiểm tra ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = ExamsBloc(repository: _ExamsRepository());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: TakeExamScreen(examId: 'exam-1')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Chọn đáp án đúng'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('take-exam-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      if (width < 600) {
        await tester.tap(find.byTooltip('Danh sách câu hỏi'));
        await tester.pumpAndSettle();
        expect(find.text('Danh sách câu hỏi (2)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Answer A'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Câu tiếp'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Viết câu trả lời'), findsOneWidget);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextFormField), 'Bài làm thử');
        await tester.pump();
        expect(
          (bloc.state as ExamInProgressState).currentAnswers['eq2'],
          'Bài làm thử',
        );
        expect(find.text('Nộp bài thi'), findsWidgets);
        tester.view.resetViewInsets();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('danh sách kỳ thi học viên ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = ExamsBloc(repository: _ExamsRepository());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: ExamListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('IELTS Reading'), findsOneWidget);
      expect(find.text('Bản nháp nội bộ'), findsNothing);
      expect(
        find.byKey(const ValueKey('exams-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('kết quả thi cá nhân ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = ExamsBloc(repository: _ExamsRepository());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: MyExamResultsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('IELTS Reading'), findsOneWidget);
      expect(find.text('8.0 / 10.0 điểm'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('my-exam-results-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
