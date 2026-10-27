import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../../data/models/exam_model.dart';

class ExamResultScreen extends StatefulWidget {
  final String examId;

  const ExamResultScreen({super.key, required this.examId});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExamsBloc>().add(LoadExamResultsEvent(widget.examId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Kỳ Thi'),
      ),
      body: BlocBuilder<ExamsBloc, ExamsState>(
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const LoadingWidget(message: 'Đang tải kết quả thi...');
          }

          if (state is ExamsErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<ExamsBloc>().add(LoadExamResultsEvent(widget.examId)),
            );
          }

          if (state is ExamResultsLoadedState) {
            final data = state.results;
            final exam = data.exam;
            final summary = data.summary;
            final attempts = data.attempts;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Exam Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title, style: AppTextStyles.h3(context)),
                        if (exam.className != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Lớp: ${exam.className}',
                            style: AppTextStyles.caption(context).copyWith(color: AppColors.neutral600),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Lượt thi', '${summary.totalAttempts}', AppColors.primary),
                            _buildSummaryItem('Điểm TB', '${summary.averageScore}', AppColors.accent),
                            _buildSummaryItem('Tỷ lệ Đạt', '${summary.passRate}%', AppColors.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Danh sách kết quả học viên (${attempts.length})', style: AppTextStyles.h4(context)),
                  const SizedBox(height: 12),

                  if (attempts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Chưa có học viên nào hoàn thành bài thi này.')),
                    )
                  else
                    ...attempts.map((att) => _buildAttemptCard(att, exam)),

                  const SizedBox(height: 24),
                  Center(
                    child: AppButton(
                      text: 'Quay lại danh sách bài thi',
                      icon: Icons.arrow_back,
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.pop(),
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2(context).copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }

  Widget _buildAttemptCard(ExamAttemptModel att, ExamModel exam) {
    final isPassed = att.isPassed;
    final color = isPassed == true
        ? AppColors.success
        : (isPassed == false ? AppColors.error : AppColors.warning);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              att.studentName != null && att.studentName!.isNotEmpty
                  ? att.studentName![0].toUpperCase()
                  : 'H',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.studentName ?? 'Học viên',
                  style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                ),
                if (att.studentCode != null)
                  Text(
                    'Mã: ${att.studentCode}',
                    style: AppTextStyles.caption(context).copyWith(color: AppColors.neutral500),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                att.score != null ? '${att.score} / ${att.maxScore}' : 'Chờ chấm',
                style: AppTextStyles.h4(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPassed == true
                      ? 'ĐẠT'
                      : (isPassed == false ? 'CHƯA ĐẠT' : 'CHỜ CHẤM TỰ LUẬN'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
