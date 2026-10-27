import 'package:equatable/equatable.dart';

abstract class ExamsEvent extends Equatable {
  const ExamsEvent();

  @override
  List<Object?> get props => [];
}

class LoadExamsEvent extends ExamsEvent {
  final String? classId;
  final String? status;

  const LoadExamsEvent({this.classId, this.status});

  @override
  List<Object?> get props => [classId, status];
}

class LoadExamDetailEvent extends ExamsEvent {
  final String id;

  const LoadExamDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateExamEvent extends ExamsEvent {
  final Map<String, dynamic> data;

  const CreateExamEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class StartExamEvent extends ExamsEvent {
  final String examId;

  const StartExamEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class UpdateStudentAnswerEvent extends ExamsEvent {
  final String examQuestionId;
  final dynamic answer;

  const UpdateStudentAnswerEvent({
    required this.examQuestionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [examQuestionId, answer];
}

class SaveExamAnswersEvent extends ExamsEvent {
  final String attemptId;
  final List<Map<String, dynamic>> answers;

  const SaveExamAnswersEvent({
    required this.attemptId,
    required this.answers,
  });

  @override
  List<Object?> get props => [attemptId, answers];
}

class SubmitExamEvent extends ExamsEvent {
  final String examId;

  const SubmitExamEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class LoadExamResultsEvent extends ExamsEvent {
  final String examId;

  const LoadExamResultsEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class LoadMyExamResultsEvent extends ExamsEvent {
  const LoadMyExamResultsEvent();
}

class GradeExamAnswerEvent extends ExamsEvent {
  final String answerId;
  final double score;
  final String? feedback;

  const GradeExamAnswerEvent({
    required this.answerId,
    required this.score,
    this.feedback,
  });

  @override
  List<Object?> get props => [answerId, score, feedback];
}

class LoadQuestionBanksEvent extends ExamsEvent {
  final String? language;
  final String? level;
  final String? search;

  const LoadQuestionBanksEvent({this.language, this.level, this.search});

  @override
  List<Object?> get props => [language, level, search];
}

class CreateQuestionBankEvent extends ExamsEvent {
  final String title;
  final String? description;
  final String? language;
  final String? level;

  const CreateQuestionBankEvent({
    required this.title,
    this.description,
    this.language,
    this.level,
  });

  @override
  List<Object?> get props => [title, description, language, level];
}

class AddQuestionToBankEvent extends ExamsEvent {
  final String bankId;
  final Map<String, dynamic> questionData;

  const AddQuestionToBankEvent({
    required this.bankId,
    required this.questionData,
  });

  @override
  List<Object?> get props => [bankId, questionData];
}
