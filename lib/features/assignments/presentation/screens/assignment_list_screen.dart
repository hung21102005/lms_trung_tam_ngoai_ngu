import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../../core/di/injection.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';
import '../widgets/deadline_countdown_widget.dart';
import '../../data/models/assignment_model.dart';
import 'student_assignments_view.dart';

class AssignmentListScreen extends StatefulWidget {
  final String classId;
  final bool isTeacher;

  const AssignmentListScreen({
    super.key,
    required this.classId,
    this.isTeacher = false,
  });

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {
  String _selectedTypeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    if (!widget.isTeacher && widget.classId.isEmpty) return;
    context.read<AssignmentsBloc>().add(
      LoadClassAssignmentsEvent(widget.classId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTeacher && widget.classId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài tập của tôi')),
        body: BlocProvider<ClassesBloc>(
          create: (_) => getIt<ClassesBloc>()..add(const FetchMyClasses()),
          child: const StudentAssignmentsView(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bài tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              context.read<AssignmentsBloc>().add(
                LoadClassAssignmentsEvent(widget.classId),
              );
            },
          ),
        ],
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/classes/${widget.classId}/assignments/create');
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tạo bài tập',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'ALL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Về nhà (Homework)', 'HOMEWORK'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ghi âm (Speaking)', 'SPEAKING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bài viết (Writing)', 'WRITING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dự án (Project)', 'PROJECT'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: BlocBuilder<AssignmentsBloc, AssignmentsState>(
              builder: (context, state) {
                if (state is AssignmentsLoadingState) {
                  return const LoadingWidget(
                    message: 'Đang tải danh sách bài tập...',
                  );
                }

                if (state is AssignmentsErrorState) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<AssignmentsBloc>().add(
                        LoadClassAssignmentsEvent(widget.classId),
                      );
                    },
                  );
                }

                if (state is ClassAssignmentsLoadedState) {
                  var filtered = state.assignments;
                  if (_selectedTypeFilter != 'ALL') {
                    filtered = filtered
                        .where((a) => a.type == _selectedTypeFilter)
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'Chưa có bài tập nào',
                      description:
                          'Chưa có bài tập nào được giao cho lớp học này.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildAssignmentCard(context, item);
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

  Widget _buildFilterChip(String label, String typeKey) {
    final isSelected = _selectedTypeFilter == typeKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTypeFilter = typeKey;
          });
        }
      },
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AssignmentModel item) {
    final iconData = _getTypeIcon(item.type);
    final iconColor = _getTypeColor(item.type);

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        context.push(
          '/assignments/${item.id}${widget.isTeacher ? '?teacher=true' : ''}',
          extra: widget.isTeacher,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thang điểm: ${item.maxScore.toStringAsFixed(0)} điểm',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              if (item.mySubmission != null)
                _buildSubmissionStatusBadge(item.mySubmission!)
              else if (!widget.isTeacher)
                _buildUnsubmittedBadge()
              else
                _buildTeacherSubmissionsBadge(item),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: AppColors.neutral600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DeadlineCountdownWidget(deadline: item.deadline),
              const Row(
                children: [
                  Text(
                    'Chi tiết',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionStatusBadge(SubmissionModel sub) {
    if (sub.status == 'GRADED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Đã chấm: ${sub.score?.toStringAsFixed(1) ?? "0"}/10',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      );
    }

    if (sub.status == 'LATE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Nộp muộn',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.warning,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Đã nộp bài',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildUnsubmittedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Chưa nộp',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral700,
        ),
      ),
    );
  }

  Widget _buildTeacherSubmissionsBadge(AssignmentModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${item.totalSubmissions} bài nộp',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SPEAKING':
        return Icons.mic;
      case 'WRITING':
        return Icons.edit_note;
      case 'PROJECT':
        return Icons.groups;
      default:
        return Icons.assignment;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SPEAKING':
        return Colors.purple;
      case 'WRITING':
        return Colors.teal;
      case 'PROJECT':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }
}
