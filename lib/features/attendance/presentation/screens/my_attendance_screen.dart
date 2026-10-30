import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../data/models/attendance_model.dart';

class MyAttendanceScreen extends StatefulWidget {
  final String studentId;

  const MyAttendanceScreen({super.key, required this.studentId});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(
      LoadStudentAttendanceEvent(widget.studentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chuyên cần'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              context.read<AttendanceBloc>().add(
                LoadStudentAttendanceEvent(widget.studentId),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoadingState) {
            return const LoadingWidget(
              message: 'Đang tải thông tin chuyên cần...',
            );
          }

          if (state is AttendanceErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<AttendanceBloc>().add(
                  LoadStudentAttendanceEvent(widget.studentId),
                );
              },
            );
          }

          if (state is StudentAttendanceLoadedState) {
            final data = state.data;
            if (AdaptiveBreakpoints.fromWidth(
                  MediaQuery.sizeOf(context).width,
                ) ==
                AdaptiveSize.mobile) {
              return _buildMobileContent(data);
            }
            return _buildContent(context, data);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMobileContent(StudentAttendanceHistoryResponseModel data) {
    final summary = data.summary;
    final rate = summary.attendanceRate.clamp(0, 100).toDouble();
    return ListView(
      key: const ValueKey('student-attendance-mobile'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          'Chuyên cần của tôi',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          '${summary.totalSessions} buổi học đã được điểm danh',
          style: const TextStyle(color: AppColors.neutral600),
        ),
        const SizedBox(height: 18),
        MobileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tỷ lệ chuyên cần',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: rate / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMobileStat('Có mặt', summary.present, AppColors.success),
            _buildMobileStat('Đi muộn', summary.late, AppColors.warning),
            _buildMobileStat('Vắng', summary.absent, AppColors.error),
            _buildMobileStat('Có phép', summary.excused, AppColors.primary),
            _buildMobileStat('Học bù', summary.makeup, Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        Text('Các buổi học', style: AppTextStyles.h4(context)),
        const SizedBox(height: 10),
        if (data.records.isEmpty)
          const MobileSectionCard(
            child: Text('Chưa có buổi học nào được ghi nhận điểm danh.'),
          ),
        for (final record in data.records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MobileSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.sessionTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _getStatusText(record.status),
                        style: TextStyle(
                          color: _getStatusColor(record.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${record.className} · Buổi ${record.sessionNumber}',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.sessionDate.split('T')[0]} · ${record.startTime}–${record.endTime}',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                  if (record.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text('Ghi chú: ${record.notes}'),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StudentAttendanceHistoryResponseModel data,
  ) {
    final summary = data.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Rate Overview Card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: summary.attendanceRate / 100.0,
                        strokeWidth: 8,
                        backgroundColor: AppColors.neutral200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          summary.attendanceRate >= 80
                              ? AppColors.success
                              : summary.attendanceRate >= 65
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                      ),
                    ),
                    Text(
                      '${summary.attendanceRate.toStringAsFixed(0)}%',
                      style: AppTextStyles.h4(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tỷ lệ chuyên cần',
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(color: AppColors.neutral500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.attendanceRate >= 80
                            ? 'Chuyên cần xuất sắc! Đạt điều kiện thi cuối khóa.'
                            : summary.attendanceRate >= 65
                            ? 'Cảnh báo: Cần tham gia học bù để đủ điều kiện thi.'
                            : 'Nguy cơ cấm thi do vắng quá số buổi quy định.',
                        style: AppTextStyles.caption(context).copyWith(
                          color: summary.attendanceRate >= 80
                              ? AppColors.success
                              : summary.attendanceRate >= 65
                              ? AppColors.warning
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat boxes
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Có mặt',
                  summary.present,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  'Đi muộn',
                  summary.late,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  'Vắng',
                  summary.absent,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  'Học bù',
                  summary.makeup,
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Records section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết các buổi học (${data.records.length})',
                style: AppTextStyles.h4(context),
              ),
              if (summary.absent > 0)
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text(
                    'Đăng ký bù',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _showMakeupDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (data.records.isEmpty)
            const EmptyStateWidget(
              title: 'Chưa có dữ liệu điểm danh',
              description: 'Chưa có buổi học nào được ghi nhận điểm danh.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.records.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = data.records[index];
                return _buildRecordCard(context, record);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    StudentAttendanceRecordModel record,
  ) {
    final statusColor = _getStatusColor(record.status);
    final statusText = _getStatusText(record.status);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.sessionTitle,
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.className} - Buổi ${record.sessionNumber}',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.sessionDate.split('T')[0]} (${record.startTime} - ${record.endTime})',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.neutral600),
                    ),
                  ],
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ghi chú: ${record.notes}',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.neutral700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return AppColors.success;
      case 'LATE':
        return AppColors.warning;
      case 'ABSENT':
        return AppColors.error;
      case 'EXCUSED':
        return AppColors.primary;
      case 'MAKEUP':
        return Colors.purple;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Có mặt';
      case 'LATE':
        return 'Đi muộn';
      case 'ABSENT':
        return 'Vắng';
      case 'EXCUSED':
        return 'Có phép';
      case 'MAKEUP':
        return 'Học bù';
      default:
        return status;
    }
  }

  void _showMakeupDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng ký học bù'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gửi yêu cầu học bù cho nhân viên học vụ xếp lịch bù phù hợp.',
              style: TextStyle(fontSize: 13, color: AppColors.neutral600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do vắng và thời gian mong muốn bù...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yêu cầu học bù đã được gửi tới phòng học vụ!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }
}
