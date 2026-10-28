import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
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
  String _mobileFilter = 'all';

  void _reload() =>
      context.read<ExamsBloc>().add(LoadExamResultsEvent(widget.examId));

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < AdaptiveBreakpoints.desktop;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Kỳ Thi'),
        actions: [
          if (isMobile)
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
            ),
        ],
      ),
      body: BlocBuilder<ExamsBloc, ExamsState>(
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const LoadingWidget(message: 'Đang tải kết quả thi...');
          }

          if (state is ExamsErrorState) {
            if (isMobile) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: MobileSectionCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Không tải được kết quả',
                          style: AppTextStyles.h4(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AppErrorWidget(message: state.message, onRetry: _reload);
          }

          if (state is ExamResultsLoadedState) {
            final data = state.results;
            final exam = data.exam;
            final summary = data.summary;
            final attempts = data.attempts;

            if (isMobile) return _buildMobileResults(data);

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
                            style: AppTextStyles.caption(context)
                                .copyWith(color: AppColors.neutral600),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              'Lượt thi',
                              '${summary.totalAttempts}',
                              AppColors.primary,
                            ),
                            _buildSummaryItem(
                              'Điểm TB',
                              '${summary.averageScore}',
                              AppColors.accent,
                            ),
                            _buildSummaryItem(
                              'Tỷ lệ Đạt',
                              '${summary.passRate}%',
                              AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Danh sách kết quả học viên (${attempts.length})',
                    style: AppTextStyles.h4(context),
                  ),
                  const SizedBox(height: 12),

                  if (attempts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Chưa có học viên nào hoàn thành bài thi này.',
                        ),
                      ),
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

  Widget _buildMobileResults(ExamResultsResponseModel data) {
    final exam = data.exam;
    final summary = data.summary;
    final attempts = data.attempts.where((attempt) {
      switch (_mobileFilter) {
        case 'passed':
          return attempt.isPassed == true;
        case 'failed':
          return attempt.isPassed == false;
        case 'pending':
          return attempt.isPassed == null;
        default:
          return true;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await context.read<ExamsBloc>().stream.firstWhere(
          (state) =>
              state is ExamResultsLoadedState || state is ExamsErrorState,
        );
      },
      child: ListView(
        key: const ValueKey('teacher-exam-results-mobile'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Tổng quan kết quả', style: AppTextStyles.h3(context)),
          const SizedBox(height: 5),
          Text(
            'Theo dõi lượt thi và kết quả của học viên',
            style: AppTextStyles.bodySmall(context)
                .copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title, style: AppTextStyles.h4(context)),
                if (exam.className?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    exam.className!,
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _mobileMetric(
                      'Lượt thi',
                      '${summary.totalAttempts}',
                      AppColors.primary,
                    ),
                    _mobileMetric(
                      'Điểm TB',
                      summary.averageScore.toStringAsFixed(1),
                      AppColors.accent,
                    ),
                    _mobileMetric(
                      'Tỷ lệ đạt',
                      '${summary.passRate.toStringAsFixed(0)}%',
                      AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Kết quả học viên', style: AppTextStyles.h4(context)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'Tất cả (${data.attempts.length})'),
                _filterChip('passed', 'Đạt'),
                _filterChip('failed', 'Chưa đạt'),
                _filterChip('pending', 'Chờ chấm'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (attempts.isEmpty)
            const MobileSectionCard(
              child: Text('Chưa có kết quả phù hợp với bộ lọc.'),
            )
          else
            for (final attempt in attempts) ...[
              _mobileAttemptCard(attempt),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _mobileMetric(String label, String value, Color color) => Container(
    constraints: const BoxConstraints(minWidth: 82),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
      ],
    ),
  );

  Widget _filterChip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _mobileFilter == value,
      onSelected: (_) => setState(() => _mobileFilter = value),
    ),
  );

  Widget _mobileAttemptCard(ExamAttemptModel attempt) {
    final status = attempt.isPassed == true
        ? 'Đạt'
        : attempt.isPassed == false
        ? 'Chưa đạt'
        : 'Chờ chấm';
    final color = attempt.isPassed == true
        ? AppColors.success
        : attempt.isPassed == false
        ? AppColors.error
        : AppColors.warning;
    return MobileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  attempt.studentName?.isNotEmpty == true
                      ? attempt.studentName![0].toUpperCase()
                      : 'H',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.studentName ?? 'Học viên',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (attempt.studentCode?.isNotEmpty == true)
                      Text(
                        attempt.studentCode!,
                        style: const TextStyle(
                          color: AppColors.neutral600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lượt ${attempt.attemptNumber}',
                  style: const TextStyle(color: AppColors.neutral600),
                ),
              ),
              Text(
                attempt.score == null
                    ? 'Chờ chấm điểm'
                    : '${attempt.score!.toStringAsFixed(1)} / ${attempt.maxScore.toStringAsFixed(1)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2(context)
              .copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.neutral600),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.studentName ?? 'Học viên',
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                if (att.studentCode != null)
                  Text(
                    'Mã: ${att.studentCode}',
                    style: AppTextStyles.caption(context)
                        .copyWith(color: AppColors.neutral500),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                att.score != null
                    ? '${att.score} / ${att.maxScore}'
                    : 'Chờ chấm',
                style: AppTextStyles.h4(context)
                    .copyWith(color: color, fontWeight: FontWeight.bold),
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
