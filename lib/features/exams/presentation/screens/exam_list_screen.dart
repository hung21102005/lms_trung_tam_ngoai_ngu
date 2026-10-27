import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../../data/models/exam_model.dart';

class ExamListScreen extends StatefulWidget {
  final String? classId;
  final bool isTeacher;

  const ExamListScreen({super.key, this.classId, this.isTeacher = false});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ExamsBloc>().add(LoadExamsEvent(classId: widget.classId));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kỳ Thi & Đánh Giá Năng Lực'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.auto_stories),
              tooltip: 'Ngân hàng câu hỏi',
              onPressed: () => context.push(RouteNames.questionBanks),
            ),
        ],
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push(RouteNames.createExam);
                if (created == true) _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đề thi mới'),
            )
          : null,
      body: isMobile
          ? _buildMobileBody()
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Đang mở thi', 'PUBLISHED'),
                        const SizedBox(width: 8),
                        if (widget.isTeacher) ...[
                          _buildFilterChip('Bản nháp', 'DRAFT'),
                          const SizedBox(width: 8),
                        ],
                        _buildFilterChip('Đã đóng', 'CLOSED'),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: BlocBuilder<ExamsBloc, ExamsState>(
                    builder: (context, state) {
                      if (state is ExamsLoadingState) {
                        return const LoadingWidget();
                      }

                      if (state is ExamsErrorState) {
                        return AppErrorWidget(
                          message: state.message,
                          onRetry: _loadData,
                        );
                      }

                      if (state is ExamsLoadedState) {
                        var list = widget.isTeacher
                            ? state.exams
                            : state.exams
                                  .where((e) => e.status != 'DRAFT')
                                  .toList();
                        if (_selectedFilter != 'ALL') {
                          list = list
                              .where((e) => e.status == _selectedFilter)
                              .toList();
                        }

                        if (list.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'Chưa có bài thi nào',
                            description: 'Các đề thi và bài kiểm tra sẽ được hiển thị tại đây khi mở.',
                            icon: Icons.quiz_outlined,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final exam = list[index];
                            return _buildExamCard(exam);
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMobileBody() {
    return BlocBuilder<ExamsBloc, ExamsState>(
      builder: (context, state) {
        if (state is ExamsLoadingState) {
          return const LoadingWidget();
        }
        if (state is ExamsErrorState) {
          return AppErrorWidget(message: state.message, onRetry: _loadData);
        }
        if (state is! ExamsLoadedState) return const SizedBox.shrink();
        var exams = widget.isTeacher
            ? state.exams
            : state.exams.where((exam) => exam.status != 'DRAFT').toList();
        if (_selectedFilter != 'ALL') {
          exams = exams
              .where((exam) => exam.status == _selectedFilter)
              .toList();
        }
        return ListView(
          key: const ValueKey('exams-mobile'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              widget.isTeacher
                  ? 'Bài kiểm tra của lớp'
                  : 'Bài kiểm tra của tôi',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              '${exams.length} bài kiểm tra',
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: MobileTokens.sectionGap),
            SizedBox(
              height: 42,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'ALL'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đang mở', 'PUBLISHED'),
                    const SizedBox(width: 8),
                    if (widget.isTeacher) ...[
                      _buildFilterChip('Bản nháp', 'DRAFT'),
                      const SizedBox(width: 8),
                    ],
                    _buildFilterChip('Đã đóng', 'CLOSED'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (exams.isEmpty)
              const MobileSectionCard(
                child: Text('Chưa có bài kiểm tra trong danh mục này.'),
              ),
            for (final exam in exams)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMobileExamCard(exam),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileExamCard(ExamModel exam) {
    final latest = exam.latestAttempt;
    final canStart =
        exam.status == 'PUBLISHED' &&
        (latest == null ||
            latest.status == 'IN_PROGRESS' ||
            exam.studentAttemptsCount < exam.maxAttempts);
    return MobileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (exam.className?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              exam.className!,
              style: const TextStyle(color: AppColors.neutral600),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            '${exam.durationMinutes} phút · ${exam.questionsCount} câu · ${exam.totalPoints.toStringAsFixed(0)} điểm',
            style: const TextStyle(color: AppColors.neutral600),
          ),
          if (latest?.score != null) ...[
            const SizedBox(height: 7),
            Text(
              'Điểm gần nhất: ${latest!.score}/${latest.maxScore}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.isTeacher)
            OutlinedButton.icon(
              onPressed: () => context.push('/exams/${exam.id}/results'),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Bảng điểm'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (latest?.score != null)
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.myExamResults),
                    icon: const Icon(Icons.grade_outlined),
                    label: const Text('Xem kết quả'),
                  ),
                if (canStart)
                  FilledButton.icon(
                    onPressed: () => context.push('/exams/${exam.id}/take'),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      latest?.status == 'IN_PROGRESS'
                          ? 'Tiếp tục làm bài'
                          : 'Bắt đầu làm bài',
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.neutral700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    Color statusColor;
    String statusText;
    switch (exam.status) {
      case 'PUBLISHED':
        statusColor = AppColors.success;
        statusText = 'Đang mở thi';
        break;
      case 'CLOSED':
        statusColor = AppColors.neutral500;
        statusText = 'Đã đóng';
        break;
      default:
        statusColor = AppColors.warning;
        statusText = 'Bản nháp';
    }

    final latestAttempt = exam.latestAttempt;
    final isPassed = latestAttempt?.isPassed;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: AppTextStyles.h4(context)),
                    if (exam.className != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lớp: ${exam.className} (${exam.classCode})',
                        style: AppTextStyles.caption(context)
                            .copyWith(color: AppColors.neutral600),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (exam.description != null && exam.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exam.description!,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: AppColors.neutral600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Metadata row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetaItem(
                Icons.timer_outlined,
                '${exam.durationMinutes} phút',
              ),
              _buildMetaItem(
                Icons.help_outline,
                '${exam.questionsCount} câu hỏi',
              ),
              _buildMetaItem(
                Icons.grade_outlined,
                'Thang ${exam.totalPoints.toStringAsFixed(0)} điểm',
              ),
              _buildMetaItem(
                Icons.check_circle_outline,
                'Đạt: ${exam.passPercentage.toStringAsFixed(0)}%',
              ),
            ],
          ),

          if (latestAttempt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPassed == true ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isPassed == true ? Icons.check_circle : Icons.cancel,
                    color: isPassed == true
                        ? AppColors.success
                        : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latestAttempt.score != null
                          ? 'Điểm thi gần nhất: ${latestAttempt.score}/${latestAttempt.maxScore} (${isPassed == true ? "ĐẠT" : "CHƯA ĐẠT"})'
                          : 'Đang chấm điểm tự luận...',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPassed == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.isTeacher) ...[
                AppButton(
                  text: 'Bảng điểm & Kết quả',
                  icon: Icons.analytics_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    context.push('/exams/${exam.id}/results');
                  },
                ),
              ] else ...[
                if (latestAttempt != null && latestAttempt.score != null) ...[
                  AppButton(
                    text: 'Xem kết quả của tôi',
                    icon: Icons.history,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      context.push(RouteNames.myExamResults);
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                if (exam.status == 'PUBLISHED' &&
                    (latestAttempt == null ||
                        latestAttempt.status == 'IN_PROGRESS' ||
                        exam.studentAttemptsCount < exam.maxAttempts))
                  AppButton(
                    text: latestAttempt?.status == 'IN_PROGRESS'
                        ? 'Tiếp tục làm bài'
                        : 'Bắt đầu làm bài thi',
                    icon: Icons.play_arrow,
                    onPressed: () {
                      context.push('/exams/${exam.id}/take');
                    },
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.neutral700),
        ),
      ],
    );
  }
}
