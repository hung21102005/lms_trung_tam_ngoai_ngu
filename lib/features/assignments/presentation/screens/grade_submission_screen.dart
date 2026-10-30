import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/assignment_model.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final String assignmentId;
  final bool embedded;

  const GradeSubmissionScreen({
    super.key,
    required this.assignmentId,
    this.embedded = false,
  });

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AssignmentsBloc>().add(
      LoadAssignmentSubmissionsEvent(widget.assignmentId),
    );
  }

  void _reload() {
    context.read<AssignmentsBloc>().add(
      LoadAssignmentSubmissionsEvent(widget.assignmentId),
    );
  }

  Future<void> _openSubmission(String studentId, {bool edit = false}) async {
    final path = RouteNames.reviewSubmission
        .replaceFirst(':id', widget.assignmentId)
        .replaceFirst(':studentId', studentId);
    await context.push(edit ? '$path?edit=true' : path);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<AssignmentsBloc, AssignmentsState>(
      builder: (context, state) {
        if (state is AssignmentsLoadingState) {
          return const LoadingWidget(message: 'Đang tải danh sách bài nộp...');
        }
        if (state is AssignmentsErrorState) {
          return AppErrorWidget(message: state.message, onRetry: _reload);
        }
        if (state is AssignmentSubmissionsLoadedState) {
          return _buildContent(state.data);
        }
        return const SizedBox.shrink();
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm điểm bài tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _reload,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildContent(AssignmentSubmissionsResponseModel data) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: AppTextStyles.h4(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statBadge(
                    'Tổng sĩ số: ${data.totalEnrolled}',
                    AppColors.neutral700,
                  ),
                  _statBadge(
                    'Đã nộp: ${data.submittedCount}',
                    AppColors.primary,
                  ),
                  _statBadge('Đã chấm: ${data.gradedCount}', AppColors.success),
                  _statBadge(
                    'Chưa nộp: ${data.notSubmittedCount}',
                    AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: data.students.isEmpty
              ? const EmptyStateWidget(
                  title: 'Chưa có dữ liệu bài nộp',
                  description: 'Không tìm thấy học viên trong lớp học này.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _studentCard(data.students[index], data),
                ),
        ),
      ],
    );
  }

  Widget _statBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _studentCard(
    StudentSubmissionItemModel item,
    AssignmentSubmissionsResponseModel data,
  ) {
    final submission = item.submission;
    final hasSubmitted = item.hasSubmitted && submission != null;
    final score = submission?.score;
    final status = !hasSubmitted
        ? 'Chưa nộp bài'
        : submission.status == 'RETURNED'
        ? 'Đang chờ làm lại'
        : score == null
        ? 'Chưa chấm bài'
        : '${score.toStringAsFixed(1)} / ${data.maxScore.toStringAsFixed(1)} điểm';
    final statusColor = !hasSubmitted
        ? AppColors.neutral600
        : score == null
        ? AppColors.warning
        : AppColors.success;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Text(
                  item.fullName.isNotEmpty
                      ? item.fullName.substring(0, 1).toUpperCase()
                      : 'H',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.userCode,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _statBadge(status, statusColor),
              if (hasSubmitted)
                OutlinedButton.icon(
                  onPressed: () => _openSubmission(item.studentId),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Xem bài làm'),
                ),
              if (score != null)
                TextButton.icon(
                  onPressed: () => _openSubmission(item.studentId, edit: true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
