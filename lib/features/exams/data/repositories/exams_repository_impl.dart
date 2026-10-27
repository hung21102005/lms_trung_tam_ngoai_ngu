import '../../domain/repositories/exams_repository.dart';
import '../datasources/exams_remote_datasource.dart';
import '../models/exam_model.dart';

class ExamsRepositoryImpl implements ExamsRepository {
  final ExamsRemoteDataSource remoteDataSource;

  ExamsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<QuestionBankModel>> getQuestionBanks({String? language, String? level, String? search}) {
    return remoteDataSource.getQuestionBanks(language: language, level: level, search: search);
  }

  @override
  Future<QuestionBankModel> getQuestionBankDetail(String id) {
    return remoteDataSource.getQuestionBankDetail(id);
  }

  @override
  Future<QuestionBankModel> createQuestionBank({
    required String title,
    String? description,
    String? language,
    String? level,
  }) {
    return remoteDataSource.createQuestionBank(
      title: title,
      description: description,
      language: language,
      level: level,
    );
  }

  @override
  Future<QuestionModel> addQuestionToBank(String bankId, Map<String, dynamic> questionData) {
    return remoteDataSource.addQuestionToBank(bankId, questionData);
  }

  @override
  Future<List<ExamModel>> getExams({String? classId, String? status}) {
    return remoteDataSource.getExams(classId: classId, status: status);
  }

  @override
  Future<ExamModel> getExamDetail(String id) {
    return remoteDataSource.getExamDetail(id);
  }

  @override
  Future<ExamModel> createExam(Map<String, dynamic> examData) {
    return remoteDataSource.createExam(examData);
  }

  @override
  Future<Map<String, dynamic>> startExam(String examId) {
    return remoteDataSource.startExam(examId);
  }

  @override
  Future<void> saveExamAnswers(String attemptId, List<Map<String, dynamic>> answers) {
    return remoteDataSource.saveExamAnswers(attemptId, answers);
  }

  @override
  Future<ExamAttemptModel> submitExam(String examId) {
    return remoteDataSource.submitExam(examId);
  }

  @override
  Future<ExamResultsResponseModel> getExamResults(String examId) {
    return remoteDataSource.getExamResults(examId);
  }

  @override
  Future<List<ExamAttemptModel>> getMyExamResults() {
    return remoteDataSource.getMyExamResults();
  }

  @override
  Future<ExamAnswerModel> gradeExamAnswer(String answerId, {required double score, String? feedback}) {
    return remoteDataSource.gradeExamAnswer(answerId, score: score, feedback: feedback);
  }
}
