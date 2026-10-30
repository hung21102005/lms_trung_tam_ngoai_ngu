import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/exam_list_screen.dart';

class FakeExamsRepository implements ExamsRepository {
  @override
  Future<List<ExamModel>> getExams({String? classId, String? status}) async {
    return [
      const ExamModel(
        id: 'exam-1',
        title: 'Kiểm tra giữa kỳ IELTS Listening',
        description: 'Bài kiểm tra đánh giá kỹ năng nghe',
        className: 'IELTS Foundation',
        classCode: 'IELTS-F-01',
        durationMinutes: 45,
        passPercentage: 50.0,
        totalPoints: 10.0,
        shuffleQuestions: false,
        maxAttempts: 1,
        status: 'PUBLISHED',
        questionsCount: 20,
      ),
      const ExamModel(
        id: 'exam-2',
        title: 'Đề thi thử TOEIC Reading',
        description: 'Đề thi luyện tập ngữ pháp',
        className: 'TOEIC 650+',
        classCode: 'TOEIC-02',
        durationMinutes: 60,
        passPercentage: 60.0,
        totalPoints: 10.0,
        shuffleQuestions: true,
        maxAttempts: 2,
        status: 'DRAFT',
        questionsCount: 30,
      ),
    ];
  }

  @override
  Future<ExamModel> getExamDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> startExam(String examId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveExamAnswers(String attemptId, List<Map<String, dynamic>> answers) async {
    throw UnimplementedError();
  }

  @override
  Future<ExamAttemptModel> submitExam(String examId) async {
    throw UnimplementedError();
  }

  @override
  Future<ExamResultsResponseModel> getExamResults(String examId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ExamAttemptModel>> getMyExamResults() async {
    return [];
  }

  @override
  Future<ExamAnswerModel> gradeExamAnswer(String answerId, {required double score, String? feedback}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<QuestionBankModel>> getQuestionBanks({String? language, String? level, String? search}) async {
    return [];
  }

  @override
  Future<QuestionBankModel> getQuestionBankDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<QuestionBankModel> createQuestionBank({
    required String title,
    String? description,
    String? language,
    String? level,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<QuestionModel> addQuestionToBank(String bankId, Map<String, dynamic> questionData) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('ExamListScreen renders exams list and filters correctly', (tester) async {
    final fakeRepo = FakeExamsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ExamsBloc>(
          create: (_) => ExamsBloc(repository: fakeRepo),
          child: const ExamListScreen(isTeacher: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Kỳ Thi & Đánh Giá Năng Lực'), findsOneWidget);

    // Verify filter chips
    expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Đang mở thi'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Bản nháp'), findsOneWidget);

    // Verify exams rendered
    expect(find.text('Kiểm tra giữa kỳ IELTS Listening'), findsOneWidget);
    expect(find.text('Đề thi thử TOEIC Reading'), findsOneWidget);

    // Verify metadata
    expect(find.text('45 phút'), findsOneWidget);
    expect(find.text('20 câu hỏi'), findsOneWidget);
  });
}
