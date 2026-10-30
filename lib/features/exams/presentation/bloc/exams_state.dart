import 'package:equatable/equatable.dart';
import '../../data/models/exam_model.dart';

abstract class ExamsState extends Equatable {
  const ExamsState();

  @override
  List<Object?> get props => [];
}

class ExamsInitialState extends ExamsState {}

class ExamsLoadingState extends ExamsState {}

class ExamsLoadedState extends ExamsState {
  final List<ExamModel> exams;

  const ExamsLoadedState(this.exams);

  @override
  List<Object?> get props => [exams];
}

class ExamDetailLoadedState extends ExamsState {
  final ExamModel exam;

  const ExamDetailLoadedState(this.exam);

  @override
  List<Object?> get props => [exam];
}

class ExamInProgressState extends ExamsState {
  final ExamModel exam;
  final ExamAttemptModel attempt;
  final Map<String, dynamic> currentAnswers; // key: examQuestionId, value: studentAnswer
  final Set<String> flaggedQuestions;
  final int currentQuestionIndex;
  final bool isSaving;

  const ExamInProgressState({
    required this.exam,
    required this.attempt,
    required this.currentAnswers,
    this.flaggedQuestions = const {},
    this.currentQuestionIndex = 0,
    this.isSaving = false,
  });

  ExamInProgressState copyWith({
    ExamModel? exam,
    ExamAttemptModel? attempt,
    Map<String, dynamic>? currentAnswers,
    Set<String>? flaggedQuestions,
    int? currentQuestionIndex,
    bool? isSaving,
  }) {
    return ExamInProgressState(
      exam: exam ?? this.exam,
      attempt: attempt ?? this.attempt,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      flaggedQuestions: flaggedQuestions ?? this.flaggedQuestions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
        exam,
        attempt,
        currentAnswers,
        flaggedQuestions,
        currentQuestionIndex,
        isSaving,
      ];
}

class ExamSubmittedState extends ExamsState {
  final ExamAttemptModel attempt;

  const ExamSubmittedState(this.attempt);

  @override
  List<Object?> get props => [attempt];
}

class ExamResultsLoadedState extends ExamsState {
  final ExamResultsResponseModel results;

  const ExamResultsLoadedState(this.results);

  @override
  List<Object?> get props => [results];
}

class MyExamResultsLoadedState extends ExamsState {
  final List<ExamAttemptModel> attempts;

  const MyExamResultsLoadedState(this.attempts);

  @override
  List<Object?> get props => [attempts];
}

class QuestionBanksLoadedState extends ExamsState {
  final List<QuestionBankModel> banks;

  const QuestionBanksLoadedState(this.banks);

  @override
  List<Object?> get props => [banks];
}

class ExamActionSuccessState extends ExamsState {
  final String message;

  const ExamActionSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class ExamsErrorState extends ExamsState {
  final String message;

  const ExamsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
