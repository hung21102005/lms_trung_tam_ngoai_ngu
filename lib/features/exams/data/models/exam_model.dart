class QuestionOptionModel {
  final String id;
  final String text;
  final String? audioUrl;
  final String? imageUrl;

  const QuestionOptionModel({
    required this.id,
    required this.text,
    this.audioUrl,
    this.imageUrl,
  });

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
      };
}

class QuestionModel {
  final String id;
  final String? questionBankId;
  final String type; // MULTIPLE_CHOICE, FILL_BLANK, MATCHING, ORDERING, ESSAY
  final String prompt;
  final String? audioUrl;
  final String? imageUrl;
  final List<QuestionOptionModel>? options;
  final dynamic correctAnswers;
  final String? explanation;
  final double points;

  const QuestionModel({
    required this.id,
    this.questionBankId,
    required this.type,
    required this.prompt,
    this.audioUrl,
    this.imageUrl,
    this.options,
    this.correctAnswers,
    this.explanation,
    this.points = 1.0,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<QuestionOptionModel>? opts;
    if (json['options'] is List) {
      opts = (json['options'] as List)
          .map((e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return QuestionModel(
      id: json['id'] as String? ?? '',
      questionBankId: json['questionBankId'] as String?,
      type: json['type'] as String? ?? 'MULTIPLE_CHOICE',
      prompt: json['prompt'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      options: opts,
      correctAnswers: json['correctAnswers'],
      explanation: json['explanation'] as String?,
      points: (json['points'] != null) ? (json['points'] as num).toDouble() : 1.0,
    );
  }
}

class QuestionBankModel {
  final String id;
  final String title;
  final String? description;
  final String? language;
  final String? level;
  final int questionCount;
  final List<QuestionModel>? questions;

  const QuestionBankModel({
    required this.id,
    required this.title,
    this.description,
    this.language,
    this.level,
    this.questionCount = 0,
    this.questions,
  });

  factory QuestionBankModel.fromJson(Map<String, dynamic> json) {
    List<QuestionModel>? qList;
    if (json['questions'] is List) {
      qList = (json['questions'] as List)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    int qCount = 0;
    if (json['_count'] is Map && json['_count']['questions'] != null) {
      qCount = json['_count']['questions'] as int;
    } else if (qList != null) {
      qCount = qList.length;
    }

    return QuestionBankModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      language: json['language'] as String?,
      level: json['level'] as String?,
      questionCount: qCount,
      questions: qList,
    );
  }
}

class ExamQuestionModel {
  final String id;
  final String examId;
  final String questionId;
  final int orderIndex;
  final double points;
  final QuestionModel question;

  const ExamQuestionModel({
    required this.id,
    required this.examId,
    required this.questionId,
    required this.orderIndex,
    required this.points,
    required this.question,
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    return ExamQuestionModel(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      orderIndex: json['orderIndex'] as int? ?? 0,
      points: (json['points'] != null) ? (json['points'] as num).toDouble() : 1.0,
      question: QuestionModel.fromJson(json['question'] as Map<String, dynamic>? ?? json),
    );
  }
}

class ExamAnswerModel {
  final String id;
  final String attemptId;
  final String examQuestionId;
  final dynamic studentAnswer;
  final bool? isCorrect;
  final double? score;
  final String? teacherFeedback;
  final String? gradedAt;
  final ExamQuestionModel? examQuestion;

  const ExamAnswerModel({
    required this.id,
    required this.attemptId,
    required this.examQuestionId,
    this.studentAnswer,
    this.isCorrect,
    this.score,
    this.teacherFeedback,
    this.gradedAt,
    this.examQuestion,
  });

  factory ExamAnswerModel.fromJson(Map<String, dynamic> json) {
    return ExamAnswerModel(
      id: json['id'] as String? ?? '',
      attemptId: json['attemptId'] as String? ?? '',
      examQuestionId: json['examQuestionId'] as String? ?? '',
      studentAnswer: json['studentAnswer'],
      isCorrect: json['isCorrect'] as bool?,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      teacherFeedback: json['teacherFeedback'] as String?,
      gradedAt: json['gradedAt'] as String?,
      examQuestion: json['examQuestion'] != null
          ? ExamQuestionModel.fromJson(json['examQuestion'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ExamAttemptModel {
  final String id;
  final String examId;
  final String studentId;
  final String? studentName;
  final String? studentCode;
  final String? studentAvatar;
  final int attemptNumber;
  final String startedAt;
  final String? submittedAt;
  final double? score;
  final double maxScore;
  final bool? isPassed;
  final String status; // IN_PROGRESS, SUBMITTED, GRADED, EXPIRED
  final List<ExamAnswerModel> answers;

  const ExamAttemptModel({
    required this.id,
    required this.examId,
    required this.studentId,
    this.studentName,
    this.studentCode,
    this.studentAvatar,
    required this.attemptNumber,
    required this.startedAt,
    this.submittedAt,
    this.score,
    required this.maxScore,
    this.isPassed,
    required this.status,
    this.answers = const [],
  });

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json) {
    List<ExamAnswerModel> ans = [];
    if (json['answers'] is List) {
      ans = (json['answers'] as List)
          .map((e) => ExamAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String? sName;
    String? sCode;
    String? sAvatar;
    if (json['student'] is Map) {
      sName = json['student']['fullName'] as String?;
      sCode = json['student']['userCode'] as String?;
      sAvatar = json['student']['avatarUrl'] as String?;
    }

    return ExamAttemptModel(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: sName,
      studentCode: sCode,
      studentAvatar: sAvatar,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      startedAt: json['startedAt'] as String? ?? '',
      submittedAt: json['submittedAt'] as String?,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      maxScore: (json['maxScore'] != null) ? (json['maxScore'] as num).toDouble() : 10.0,
      isPassed: json['isPassed'] as bool?,
      status: json['status'] as String? ?? 'IN_PROGRESS',
      answers: ans,
    );
  }
}

class ExamModel {
  final String id;
  final String title;
  final String? description;
  final String? classId;
  final String? className;
  final String? classCode;
  final int durationMinutes;
  final double passPercentage;
  final double totalPoints;
  final bool shuffleQuestions;
  final int maxAttempts;
  final String status; // DRAFT, PUBLISHED, CLOSED
  final String? startTime;
  final String? endTime;
  final int questionsCount;
  final int attemptsCount;
  final int studentAttemptsCount;
  final ExamAttemptModel? latestAttempt;
  final List<ExamQuestionModel> examQuestions;

  const ExamModel({
    required this.id,
    required this.title,
    this.description,
    this.classId,
    this.className,
    this.classCode,
    required this.durationMinutes,
    required this.passPercentage,
    required this.totalPoints,
    required this.shuffleQuestions,
    required this.maxAttempts,
    required this.status,
    this.startTime,
    this.endTime,
    this.questionsCount = 0,
    this.attemptsCount = 0,
    this.studentAttemptsCount = 0,
    this.latestAttempt,
    this.examQuestions = const [],
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    String? cName;
    String? cCode;
    if (json['class'] is Map) {
      cName = json['class']['name'] as String?;
      cCode = json['class']['code'] as String?;
    }

    int qCount = 0;
    int aCount = 0;
    if (json['_count'] is Map) {
      qCount = json['_count']['examQuestions'] as int? ?? 0;
      aCount = json['_count']['attempts'] as int? ?? 0;
    }

    List<ExamQuestionModel> eqList = [];
    if (json['examQuestions'] is List) {
      eqList = (json['examQuestions'] as List)
          .map((e) => ExamQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      qCount = eqList.length;
    }

    ExamAttemptModel? latest;
    if (json['latestAttempt'] is Map) {
      latest = ExamAttemptModel.fromJson(json['latestAttempt'] as Map<String, dynamic>);
    }

    return ExamModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      classId: json['classId'] as String?,
      className: cName,
      classCode: cCode,
      durationMinutes: json['durationMinutes'] as int? ?? 45,
      passPercentage:
          json['passPercentage'] != null ? (json['passPercentage'] as num).toDouble() : 50.0,
      totalPoints:
          json['totalPoints'] != null ? (json['totalPoints'] as num).toDouble() : 10.0,
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? false,
      maxAttempts: json['maxAttempts'] as int? ?? 1,
      status: json['status'] as String? ?? 'DRAFT',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      questionsCount: qCount,
      attemptsCount: aCount,
      studentAttemptsCount: json['studentAttemptsCount'] as int? ?? 0,
      latestAttempt: latest,
      examQuestions: eqList,
    );
  }
}

class ExamResultsSummaryModel {
  final int totalAttempts;
  final int gradedCount;
  final int passedCount;
  final double passRate;
  final double averageScore;

  const ExamResultsSummaryModel({
    required this.totalAttempts,
    required this.gradedCount,
    required this.passedCount,
    required this.passRate,
    required this.averageScore,
  });

  factory ExamResultsSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExamResultsSummaryModel(
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      gradedCount: json['gradedCount'] as int? ?? 0,
      passedCount: json['passedCount'] as int? ?? 0,
      passRate: (json['passRate'] != null) ? (json['passRate'] as num).toDouble() : 0.0,
      averageScore:
          (json['averageScore'] != null) ? (json['averageScore'] as num).toDouble() : 0.0,
    );
  }
}

class ExamResultsResponseModel {
  final ExamModel exam;
  final ExamResultsSummaryModel summary;
  final List<ExamAttemptModel> attempts;

  const ExamResultsResponseModel({
    required this.exam,
    required this.summary,
    required this.attempts,
  });

  factory ExamResultsResponseModel.fromJson(Map<String, dynamic> json) {
    final attemptsList = (json['attempts'] as List? ?? [])
        .map((e) => ExamAttemptModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ExamResultsResponseModel(
      exam: ExamModel.fromJson(json['exam'] as Map<String, dynamic>),
      summary: ExamResultsSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      attempts: attemptsList,
    );
  }
}
