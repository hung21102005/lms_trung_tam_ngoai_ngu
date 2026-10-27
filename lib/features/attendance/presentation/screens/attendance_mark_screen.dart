import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../data/models/attendance_model.dart';

class AttendanceMarkScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceMarkScreen({super.key, required this.sessionId});

  @override
  State<AttendanceMarkScreen> createState() => _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends State<AttendanceMarkScreen> {
  final Map<String, TextEditingController> _notesControllers = {};

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(
      LoadSessionAttendanceEvent(widget.sessionId),
    );
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh buổi học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              context.read<AttendanceBloc>().add(
                LoadSessionAttendanceEvent(widget.sessionId),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is SessionAttendanceLoadedState &&
              state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is AttendanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoadingState) {
            return const LoadingWidget(
              message: 'Đang tải danh sách học viên...',
            );
          }

          if (state is AttendanceErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<AttendanceBloc>().add(
                  LoadSessionAttendanceEvent(widget.sessionId),
                );
              },
            );
          }

          if (state is SessionAttendanceLoadedState) {
            final data = state.data;
            return _buildContent(context, data, state.isSubmitting);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SessionAttendanceResponseModel data,
    bool isSubmitting,
  ) {
    for (final s in data.students) {
      if (!_notesControllers.containsKey(s.studentId)) {
        _notesControllers[s.studentId] = TextEditingController(
          text: s.notes ?? '',
        );
      }
    }

    int countPresent = 0;
    int countLate = 0;
    int countAbsent = 0;
    int countExcused = 0;

    for (final s in data.students) {
      final status = s.status ?? 'PRESENT';
      if (status == 'PRESENT') {
        countPresent++;
      } else if (status == 'LATE') {
        countLate++;
      } else if (status == 'ABSENT') {
        countAbsent++;
      } else if (status == 'EXCUSED') {
        countExcused++;
      }
    }

    return Column(
      children: [
        // Header session card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: AppTextStyles.h4(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Buổi ${data.sessionNumber}',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Lớp: ${data.className} (${data.classCode})',
                style: AppTextStyles.bodyMedium(context)
                    .copyWith(color: AppColors.neutral600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.date.split('T')[0]}  |  ${data.startTime} - ${data.endTime}',
                    style: AppTextStyles.caption(context)
                        .copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Summary chips & Quick action
              Row(
                children: [
                  _buildStatBadge('Có mặt: $countPresent', AppColors.success),
                  const SizedBox(width: 8),
                  _buildStatBadge('Muộn: $countLate', AppColors.warning),
                  const SizedBox(width: 8),
                  _buildStatBadge('Vắng: $countAbsent', AppColors.error),
                  const SizedBox(width: 8),
                  _buildStatBadge('Phép: $countExcused', AppColors.primary),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'Tất cả có mặt',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      for (final s in data.students) {
                        context.read<AttendanceBloc>().add(
                          UpdateStudentStatusEvent(
                            studentId: s.studentId,
                            status: 'PRESENT',
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Students list
        Expanded(
          child: data.students.isEmpty
              ? const EmptyStateWidget(
                  title: 'Chưa có học viên',
                  description:
                      'Lớp học này hiện chưa có học viên nào được xếp lớp.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.students.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = data.students[index];
                    return _buildStudentAttendanceCard(context, student);
                  },
                ),
        ),

        // Bottom submit bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: AppButton(
              text: 'Lưu & Hoàn Tất Điểm Danh',
              icon: Icons.check_circle_outline,
              isLoading: isSubmitting,
              onPressed: () {
                final payload = data.students.map((s) {
                  final notes = _notesControllers[s.studentId]?.text.trim();
                  return {
                    'studentId': s.studentId,
                    'status': s.status ?? 'PRESENT',
                    if (notes != null && notes.isNotEmpty) 'notes': notes,
                  };
                }).toList();

                context.read<AttendanceBloc>().add(
                  BatchMarkAttendanceEvent(
                    sessionId: data.sessionId,
                    students: payload,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(
    BuildContext context,
    StudentAttendanceItemModel student,
  ) {
    final currentStatus = student.status ?? 'PRESENT';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName.substring(0, 1).toUpperCase()
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
                      student.fullName,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      student.userCode,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status choice chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChoiceChip(
                label: 'Có mặt',
                statusKey: 'PRESENT',
                currentStatus: currentStatus,
                activeColor: AppColors.success,
                onSelected: () => _updateStatus(student.studentId, 'PRESENT'),
              ),
              _buildChoiceChip(
                label: 'Đi muộn',
                statusKey: 'LATE',
                currentStatus: currentStatus,
                activeColor: AppColors.warning,
                onSelected: () => _updateStatus(student.studentId, 'LATE'),
              ),
              _buildChoiceChip(
                label: 'Vắng',
                statusKey: 'ABSENT',
                currentStatus: currentStatus,
                activeColor: AppColors.error,
                onSelected: () => _updateStatus(student.studentId, 'ABSENT'),
              ),
              _buildChoiceChip(
                label: 'Có phép',
                statusKey: 'EXCUSED',
                currentStatus: currentStatus,
                activeColor: AppColors.primary,
                onSelected: () => _updateStatus(student.studentId, 'EXCUSED'),
              ),
            ],
          ),

          // Notes input if not present
          if (currentStatus != 'PRESENT') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _notesControllers[student.studentId],
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: currentStatus == 'ABSENT'
                    ? 'Lý do vắng mặt (thông báo cho phụ huynh)...'
                    : 'Ghi chú thêm (vd: muộn 15 phút)...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String statusKey,
    required String currentStatus,
    required Color activeColor,
    required VoidCallback onSelected,
  }) {
    final isSelected = currentStatus == statusKey;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : activeColor.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : activeColor.withAlpha(60),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : activeColor,
          ),
        ),
      ),
    );
  }

  void _updateStatus(String studentId, String status) {
    context.read<AttendanceBloc>().add(
      UpdateStudentStatusEvent(
        studentId: studentId,
        status: status,
        notes: _notesControllers[studentId]?.text,
      ),
    );
  }
}
