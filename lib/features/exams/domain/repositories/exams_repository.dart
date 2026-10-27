import '../../data/models/exam_model.dart';

abstract class ExamsRepository {
  Future<List<QuestionBankModel>> getQuestionBanks({String? language, String? level, String? search});
  Future<QuestionBankModel> getQuestionBankDetail(String id);
  Future<QuestionBankModel> createQuestionBank({
    required String title,
    String? description,
    String? language,
    String? level,
  });
  Future<QuestionModel> addQuestionToBank(String bankId, Map<String, dynamic> questionData);
  Future<List<ExamModel>> getExams({String? classId, String? status});
  Future<ExamModel> getExamDetail(String id);
  Future<ExamModel> createExam(Map<String, dynamic> examData);
  Future<Map<String, dynamic>> startExam(String examId);
  Future<void> saveExamAnswers(String attemptId, List<Map<String, dynamic>> answers);
  Future<ExamAttemptModel> submitExam(String examId);
  Future<ExamResultsResponseModel> getExamResults(String examId);
  Future<List<ExamAttemptModel>> getMyExamResults();
  Future<ExamAnswerModel> gradeExamAnswer(String answerId, {required double score, String? feedback});
}
