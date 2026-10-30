import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/exam_model.dart';

abstract class ExamsRemoteDataSource {
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

class ExamsRemoteDataSourceImpl implements ExamsRemoteDataSource {
  final ApiClient apiClient;

  ExamsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<QuestionBankModel>> getQuestionBanks({String? language, String? level, String? search}) async {
    final queryParams = <String, dynamic>{};
    if (language != null) queryParams['language'] = language;
    if (level != null) queryParams['level'] = level;
    if (search != null) queryParams['search'] = search;

    final response = await apiClient.get(
      ApiEndpoints.questionBanks,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list.map((e) => QuestionBankModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<QuestionBankModel> getQuestionBankDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.questionBankDetail(id));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return QuestionBankModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<QuestionBankModel> createQuestionBank({
    required String title,
    String? description,
    String? language,
    String? level,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.questionBanks,
      data: {
        'title': title,
        'description': ?description,
        'language': ?language,
        'level': ?level,
      },
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return QuestionBankModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<QuestionModel> addQuestionToBank(String bankId, Map<String, dynamic> questionData) async {
    final response = await apiClient.post(
      ApiEndpoints.questionBankQuestions(bankId),
      data: questionData,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return QuestionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<ExamModel>> getExams({String? classId, String? status}) async {
    final queryParams = <String, dynamic>{};
    if (classId != null) queryParams['classId'] = classId;
    if (status != null) queryParams['status'] = status;

    final response = await apiClient.get(
      ApiEndpoints.exams,
      queryParameters: queryParams,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ExamModel> getExamDetail(String id) async {
    final response = await apiClient.get(ApiEndpoints.examDetail(id));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    final response = await apiClient.post(
      ApiEndpoints.exams,
      data: examData,
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> startExam(String examId) async {
    final response = await apiClient.post(ApiEndpoints.startExam(examId));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final map = data as Map<String, dynamic>;
    final attemptJson = (map['attempt'] ?? {}) as Map<String, dynamic>;
    final examJson = (map['exam'] ?? {}) as Map<String, dynamic>;

    return {
      'attempt': ExamAttemptModel.fromJson(attemptJson),
      'exam': ExamModel.fromJson(examJson),
      'message': map['message'] as String? ?? '',
    };
  }

  @override
  Future<void> saveExamAnswers(String attemptId, List<Map<String, dynamic>> answers) async {
    await apiClient.patch(
      ApiEndpoints.saveExamAnswers(attemptId),
      data: {'answers': answers},
    );
  }

  @override
  Future<ExamAttemptModel> submitExam(String examId) async {
    final response = await apiClient.post(ApiEndpoints.submitExam(examId));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final map = data as Map<String, dynamic>;
    final attemptJson = (map['attempt'] ?? map) as Map<String, dynamic>;
    return ExamAttemptModel.fromJson(attemptJson);
  }

  @override
  Future<ExamResultsResponseModel> getExamResults(String examId) async {
    final response = await apiClient.get(ApiEndpoints.examResults(examId));
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return ExamResultsResponseModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<ExamAttemptModel>> getMyExamResults() async {
    final response = await apiClient.get(ApiEndpoints.myExamResults);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    final list = data is List
        ? data
        : (data is Map<String, dynamic> && data['items'] is List ? data['items'] as List : []);
    return list.map((e) => ExamAttemptModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ExamAnswerModel> gradeExamAnswer(String answerId, {required double score, String? feedback}) async {
    final response = await apiClient.patch(
      ApiEndpoints.gradeExamAnswer(answerId),
      data: {
        'score': score,
        'feedback': ?feedback,
      },
    );
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    return ExamAnswerModel.fromJson(data as Map<String, dynamic>);
  }
}
