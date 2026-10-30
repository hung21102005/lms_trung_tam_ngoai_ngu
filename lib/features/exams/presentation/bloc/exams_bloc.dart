import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/exams_repository.dart';
import 'exams_event.dart';
import 'exams_state.dart';

class ExamsBloc extends Bloc<ExamsEvent, ExamsState> {
  final ExamsRepository repository;

  ExamsBloc({required this.repository}) : super(ExamsInitialState()) {
    on<LoadExamsEvent>(_onLoadExams);
    on<LoadExamDetailEvent>(_onLoadExamDetail);
    on<CreateExamEvent>(_onCreateExam);
    on<StartExamEvent>(_onStartExam);
    on<UpdateStudentAnswerEvent>(_onUpdateStudentAnswer);
    on<SaveExamAnswersEvent>(_onSaveExamAnswers);
    on<SubmitExamEvent>(_onSubmitExam);
    on<LoadExamResultsEvent>(_onLoadExamResults);
    on<LoadMyExamResultsEvent>(_onLoadMyExamResults);
    on<GradeExamAnswerEvent>(_onGradeExamAnswer);
    on<LoadQuestionBanksEvent>(_onLoadQuestionBanks);
    on<CreateQuestionBankEvent>(_onCreateQuestionBank);
    on<AddQuestionToBankEvent>(_onAddQuestionToBank);
  }

  Future<void> _onLoadExams(LoadExamsEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final exams = await repository.getExams(classId: event.classId, status: event.status);
      emit(ExamsLoadedState(exams));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadExamDetail(LoadExamDetailEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final exam = await repository.getExamDetail(event.id);
      emit(ExamDetailLoadedState(exam));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onCreateExam(CreateExamEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      await repository.createExam(event.data);
      emit(const ExamActionSuccessState('Tạo đề thi thành công!'));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onStartExam(StartExamEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final res = await repository.startExam(event.examId);
      final attempt = res['attempt'];
      final exam = res['exam'];

      final Map<String, dynamic> initialAnswers = {};
      for (final a in attempt.answers) {
        if (a.studentAnswer != null) {
          initialAnswers[a.examQuestionId] = a.studentAnswer;
        }
      }

      emit(ExamInProgressState(
        exam: exam,
        attempt: attempt,
        currentAnswers: initialAnswers,
      ));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  void _onUpdateStudentAnswer(UpdateStudentAnswerEvent event, Emitter<ExamsState> emit) {
    if (state is ExamInProgressState) {
      final current = state as ExamInProgressState;
      final newAnswers = Map<String, dynamic>.from(current.currentAnswers);
      newAnswers[event.examQuestionId] = event.answer;
      emit(current.copyWith(currentAnswers: newAnswers));
    }
  }

  Future<void> _onSaveExamAnswers(SaveExamAnswersEvent event, Emitter<ExamsState> emit) async {
    if (state is ExamInProgressState) {
      final current = state as ExamInProgressState;
      emit(current.copyWith(isSaving: true));
      try {
        await repository.saveExamAnswers(event.attemptId, event.answers);
        emit(current.copyWith(isSaving: false));
      } catch (e) {
        emit(current.copyWith(isSaving: false));
      }
    }
  }

  Future<void> _onSubmitExam(SubmitExamEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final attempt = await repository.submitExam(event.examId);
      emit(ExamSubmittedState(attempt));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadExamResults(LoadExamResultsEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final results = await repository.getExamResults(event.examId);
      emit(ExamResultsLoadedState(results));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadMyExamResults(LoadMyExamResultsEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final attempts = await repository.getMyExamResults();
      emit(MyExamResultsLoadedState(attempts));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onGradeExamAnswer(GradeExamAnswerEvent event, Emitter<ExamsState> emit) async {
    try {
      await repository.gradeExamAnswer(
        event.answerId,
        score: event.score,
        feedback: event.feedback,
      );
      emit(const ExamActionSuccessState('Đã chấm điểm câu trả lời thành công!'));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadQuestionBanks(LoadQuestionBanksEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      final banks = await repository.getQuestionBanks(
        language: event.language,
        level: event.level,
        search: event.search,
      );
      emit(QuestionBanksLoadedState(banks));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onCreateQuestionBank(CreateQuestionBankEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      await repository.createQuestionBank(
        title: event.title,
        description: event.description,
        language: event.language,
        level: event.level,
      );
      emit(const ExamActionSuccessState('Tạo ngân hàng câu hỏi thành công!'));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }

  Future<void> _onAddQuestionToBank(AddQuestionToBankEvent event, Emitter<ExamsState> emit) async {
    emit(ExamsLoadingState());
    try {
      await repository.addQuestionToBank(event.bankId, event.questionData);
      emit(const ExamActionSuccessState('Thêm câu hỏi vào ngân hàng thành công!'));
    } catch (e) {
      emit(ExamsErrorState(e.toString()));
    }
  }
}
