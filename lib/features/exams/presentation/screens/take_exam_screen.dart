import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/essay_question_widget.dart';
import '../widgets/fill_blank_question_widget.dart';
import '../widgets/multiple_choice_question_widget.dart';
import '../../data/models/exam_model.dart';

class TakeExamScreen extends StatefulWidget {
  final String examId;

  const TakeExamScreen({super.key, required this.examId});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  int _currentIndex = 0;
  final Set<String> _flaggedQuestionIds = {};
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    context.read<ExamsBloc>().add(StartExamEvent(widget.examId));
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoSave(ExamInProgressState state) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final answersList = state.currentAnswers.entries
          .map((e) => {'examQuestionId': e.key, 'studentAnswer': e.value})
          .toList();

      context.read<ExamsBloc>().add(SaveExamAnswersEvent(
            attemptId: state.attempt.id,
            answers: answersList,
          ));
    });
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận nộp bài thi'),
        content: const Text(
          'Bạn có chắc chắn muốn nộp bài thi ngay bây giờ? Sau khi nộp bài, bạn sẽ không thể chỉnh sửa câu trả lời.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Tiếp tục làm bài'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _submit();
            },
            child: const Text('Nộp bài thi'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    context.read<ExamsBloc>().add(SubmitExamEvent(widget.examId));
  }

  void _showQuestionGridSheet(List<ExamQuestionModel> questions, Map<String, dynamic> answers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh sách câu hỏi (${questions.length})', style: AppTextStyles.h4(context)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLegend(AppColors.primary, 'Đã làm'),
                  const SizedBox(width: 16),
                  _buildLegend(AppColors.warning, 'Cần xem lại'),
                  const SizedBox(width: 16),
                  _buildLegend(AppColors.neutral300, 'Chưa làm'),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, idx) {
                    final eq = questions[idx];
                    final isAnswered = answers[eq.id] != null;
                    final isFlagged = _flaggedQuestionIds.contains(eq.id);
                    final isCurrent = idx == _currentIndex;

                    Color bg = AppColors.neutral100;
                    Color textCol = AppColors.neutral700;
                    if (isAnswered) {
                      bg = AppColors.primary;
                      textCol = Colors.white;
                    }
                    if (isFlagged) {
                      bg = AppColors.warning;
                      textCol = Colors.white;
                    }

                    return InkWell(
                      onTap: () {
                        setState(() => _currentIndex = idx);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent ? Border.all(color: AppColors.neutral900, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: textCol,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmSubmit();
        }
      },
      child: BlocConsumer<ExamsBloc, ExamsState>(
        listener: (context, state) {
          if (state is ExamSubmittedState) {
            context.pushReplacement('/exams/${widget.examId}/results');
          }
        },
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const Scaffold(
              body: Center(
                child: LoadingWidget(message: 'Đang tải đề thi & chuẩn bị phòng thi...'),
              ),
            );
          }

          if (state is ExamsErrorState) {
            return Scaffold(
              appBar: AppBar(title: const Text('Phòng Thi Trực Tuyến')),
              body: AppErrorWidget(
                message: state.message,
                onRetry: () => context.read<ExamsBloc>().add(StartExamEvent(widget.examId)),
              ),
            );
          }

          if (state is ExamInProgressState) {
            final exam = state.exam;
            final questions = exam.examQuestions;

            if (questions.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(exam.title)),
                body: const Center(child: Text('Đề thi chưa có câu hỏi nào.')),
              );
            }

            final currentQuestionModel = questions[_currentIndex];
            final currentAnswer = state.currentAnswers[currentQuestionModel.id];
            final isFlagged = _flaggedQuestionIds.contains(currentQuestionModel.id);
            final startedAtDate = DateTime.tryParse(state.attempt.startedAt) ?? DateTime.now();

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Nộp bài thi',
                  onPressed: _confirmSubmit,
                ),
                title: Text(
                  exam.title,
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  Center(
                    child: CountdownTimerWidget(
                      startedAt: startedAtDate,
                      durationMinutes: exam.durationMinutes,
                      onTimeExpired: _submit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
                    tooltip: 'Danh sách câu hỏi',
                    onPressed: () => _showQuestionGridSheet(questions, state.currentAnswers),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Progress line
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / questions.length,
                    backgroundColor: AppColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),

                  // Header question bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu ${_currentIndex + 1} / ${questions.length}',
                          style: AppTextStyles.h4(context).copyWith(color: AppColors.primary),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${currentQuestionModel.points.toStringAsFixed(1)} điểm',
                                style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                isFlagged ? Icons.bookmark : Icons.bookmark_border,
                                color: isFlagged ? AppColors.warning : AppColors.neutral500,
                              ),
                              tooltip: isFlagged ? 'Bỏ đánh dấu' : 'Đánh dấu cần xem lại',
                              onPressed: () {
                                setState(() {
                                  if (isFlagged) {
                                    _flaggedQuestionIds.remove(currentQuestionModel.id);
                                  } else {
                                    _flaggedQuestionIds.add(currentQuestionModel.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: AppCard(
                        padding: const EdgeInsets.all(20),
                        child: _buildQuestionRenderer(
                          currentQuestionModel.question,
                          currentAnswer,
                          (newAns) {
                            context.read<ExamsBloc>().add(UpdateStudentAnswerEvent(
                                  examQuestionId: currentQuestionModel.id,
                                  answer: newAns,
                                ));
                            _scheduleAutoSave(state);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Navigation bottom bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _currentIndex > 0
                              ? () => setState(() => _currentIndex--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Câu trước'),
                        ),
                        if (state.isSaving)
                          const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 6),
                              Text('Đang lưu...', style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                            ],
                          ),
                        if (_currentIndex < questions.length - 1)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => setState(() => _currentIndex++),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Câu tiếp'),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _confirmSubmit,
                            icon: const Icon(Icons.check),
                            label: const Text('Nộp bài thi'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildQuestionRenderer(
    QuestionModel question,
    dynamic selectedAnswer,
    ValueChanged<dynamic> onAnswerChanged,
  ) {
    switch (question.type) {
      case 'FILL_BLANK':
        return FillBlankQuestionWidget(
          question: question,
          selectedAnswer: selectedAnswer,
          onAnswerChanged: onAnswerChanged,
        );
      case 'ESSAY':
        return EssayQuestionWidget(
          question: question,
          selectedAnswer: selectedAnswer,
          onAnswerChanged: onAnswerChanged,
        );
      default:
        return MultipleChoiceQuestionWidget(
          question: question,
          selectedAnswer: selectedAnswer,
          onAnswerChanged: onAnswerChanged,
        );
    }
  }
}
