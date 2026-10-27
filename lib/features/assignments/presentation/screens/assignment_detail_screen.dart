import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/utils/attachment_url.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/linkified_text.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';
import '../widgets/deadline_countdown_widget.dart';
import 'grade_submission_screen.dart';
import '../../data/models/assignment_model.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final bool isTeacher;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    this.isTeacher = false,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  int _teacherTab = 0;
  int _studentsReloadKey = 0;

  Future<void> _editAssignment() async {
    final saved = await context.push<bool>(
      '/assignments/${widget.assignmentId}/edit',
    );
    if (mounted && saved == true) {
      context.read<AssignmentsBloc>().add(
        LoadAssignmentDetailEvent(widget.assignmentId),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<AssignmentsBloc>().add(
      LoadAssignmentDetailEvent(widget.assignmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              if (widget.isTeacher && _teacherTab == 1) {
                setState(() => _studentsReloadKey++);
                return;
              }
              context.read<AssignmentsBloc>().add(
                LoadAssignmentDetailEvent(widget.assignmentId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isTeacher)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _teacherTabButton(
                    0,
                    Icons.description_outlined,
                    'Nội dung bài tập',
                  ),
                  _teacherTabButton(
                    1,
                    Icons.people_outline,
                    'Danh sách học viên',
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.isTeacher && _teacherTab == 1
                ? BlocProvider<AssignmentsBloc>(
                    key: ValueKey(_studentsReloadKey),
                    create: (_) => getIt<AssignmentsBloc>(),
                    child: GradeSubmissionScreen(
                      assignmentId: widget.assignmentId,
                      embedded: true,
                    ),
                  )
                : _assignmentContent(),
          ),
        ],
      ),
    );
  }

  Widget _teacherTabButton(int index, IconData icon, String label) {
    final selected = _teacherTab == index;
    return selected
        ? FilledButton.icon(
            onPressed: () => setState(() => _teacherTab = index),
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: () => setState(() => _teacherTab = index),
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }

  Widget _assignmentContent() {
    return BlocBuilder<AssignmentsBloc, AssignmentsState>(
      builder: (context, state) {
        if (state is AssignmentsLoadingState) {
          return const LoadingWidget(message: 'Đang tải thông tin bài tập...');
        }

        if (state is AssignmentsErrorState) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () {
              context.read<AssignmentsBloc>().add(
                LoadAssignmentDetailEvent(widget.assignmentId),
              );
            },
          );
        }

        if (state is AssignmentDetailLoadedState) {
          final assignment = state.assignment;
          return _buildContent(context, assignment);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, AssignmentModel assignment) {
    if (!widget.isTeacher &&
        AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
            AdaptiveSize.mobile) {
      return _buildMobileStudentDetail(assignment);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isTeacher) ...[
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _editAssignment,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Sửa bài tập'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Header info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.title, style: AppTextStyles.h3(context)),
                    const SizedBox(height: 6),
                    Text(
                      'Lớp: ${assignment.className ?? ""} (${assignment.classCode ?? ""})',
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Thang ${assignment.maxScore.toStringAsFixed(0)} điểm',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Deadline & Type Bar
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Loại: ${_getTypeName(assignment.type)}',
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                DeadlineCountdownWidget(deadline: assignment.deadline),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Instructions & Description
          Text('Yêu cầu & Đề bài', style: AppTextStyles.h4(context)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: LinkifiedText(
              text: assignment.description ?? 'Không có mô tả chi tiết.',
              style: AppTextStyles.bodyMedium(context).copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // Attachments
          if (assignment.attachments.isNotEmpty) ...[
            Text(
              'Tài liệu hướng dẫn đính kèm',
              style: AppTextStyles.h4(context),
            ),
            const SizedBox(height: 10),
            ...assignment.attachments.map((att) => _buildAttachmentTile(att)),
            const SizedBox(height: 24),
          ],

          // Teacher Action Section
          if (widget.isTeacher) ...[
            Text(
              'Tình trạng nộp bài của lớp',
              style: AppTextStyles.h4(context),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã nộp: ${assignment.totalSubmissions} bài',
                          style: AppTextStyles.h4(context)
                              .copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đã chấm: ${assignment.gradedCount} bài · Chưa chấm: ${assignment.totalSubmissions - assignment.gradedCount} bài',
                          style: AppTextStyles.caption(context)
                              .copyWith(color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.grading, size: 18),
                    label: const Text('Chấm điểm bài nộp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => _teacherTab = 1),
                  ),
                ],
              ),
            ),
          ],

          // Student Submission Section
          if (!widget.isTeacher) ...[
            Text('Bài làm của bạn', style: AppTextStyles.h4(context)),
            const SizedBox(height: 12),
            if (assignment.mySubmission != null)
              _buildStudentSubmissionCard(assignment, assignment.mySubmission!)
            else
              _buildNotSubmittedCard(assignment),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileStudentDetail(AssignmentModel assignment) {
    final sub = assignment.mySubmission;
    final deadline = DateTime.tryParse(assignment.deadline ?? '')?.toLocal();
    final canEdit =
        sub == null ||
        sub.status == 'RETURNED' ||
        sub.status == 'DRAFT' ||
        (sub.status != 'GRADED' &&
            sub.status != 'GRADED_PENDING' &&
            (deadline == null || DateTime.now().isBefore(deadline)));
    final status = sub == null
        ? 'Chưa nộp'
        : switch (sub.status) {
            'DRAFT' => 'Bản nháp',
            'RETURNED' => 'Cần làm lại',
            'GRADED' => 'Đã chấm',
            'GRADED_PENDING' => 'Chờ công bố',
            'LATE' => 'Đã nộp muộn',
            _ => 'Chờ giảng viên chấm',
          };
    final statusColor = sub?.status == 'GRADED'
        ? AppColors.success
        : sub?.status == 'RETURNED'
        ? AppColors.error
        : AppColors.primary;
    return ListView(
      key: const ValueKey('student-assignment-mobile-detail'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          assignment.className ?? 'Lớp học',
          style: const TextStyle(color: AppColors.neutral600),
        ),
        const SizedBox(height: 5),
        Text(
          assignment.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MobileStatusPill(label: status, color: statusColor),
            MobileStatusPill(
              label: _getTypeName(assignment.type),
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        MobileSectionCard(
          child: Row(
            children: [
              const Icon(Icons.event_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hạn nộp',
                      style: TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      deadline == null
                          ? 'Không giới hạn'
                          : '${deadline.day}/${deadline.month}/${deadline.year} · ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                '${assignment.maxScore.toStringAsFixed(0)} điểm',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        const Text(
          'Yêu cầu bài tập',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        MobileSectionCard(
          child: LinkifiedText(
            text: assignment.description?.isNotEmpty == true
                ? assignment.description!
                : 'Giảng viên chưa thêm hướng dẫn chi tiết.',
          ),
        ),
        if (assignment.attachments.isNotEmpty) ...[
          const SizedBox(height: MobileTokens.sectionGap),
          const Text(
            'Tài liệu hướng dẫn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          MobileSectionCard(
            child: Column(
              children: [
                for (final file in assignment.attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () => _openAttachment(file.url),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: MobileTokens.sectionGap),
        const Text(
          'Bài làm của bạn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (sub == null)
          const MobileSectionCard(child: Text('Bạn chưa nộp bài tập này.'))
        else
          MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sub.status == 'GRADED' && sub.score != null) ...[
                  Text(
                    '${sub.score!.toStringAsFixed(1)} / ${assignment.maxScore.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (sub.status == 'GRADED' &&
                    sub.feedback?.isNotEmpty == true) ...[
                  const Text(
                    'Nhận xét của giảng viên',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(sub.feedback!),
                  const SizedBox(height: 12),
                ],
                if (sub.content?.isNotEmpty == true) ...[
                  const Text(
                    'Nội dung đã nộp',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(sub.content!),
                ],
                for (final file in sub.fileUrls)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () => _openAttachment(file.url),
                  ),
                if (sub.content?.isNotEmpty != true && sub.fileUrls.isEmpty)
                  const Text('Bài làm chưa có nội dung hoặc tệp.'),
              ],
            ),
          ),
        if (canEdit) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: MobileTokens.touchTarget,
            child: FilledButton.icon(
              onPressed: () async {
                final updated = await context.push<bool>(
                  '/assignments/${assignment.id}/submit',
                );
                if (mounted && updated == true) {
                  context.read<AssignmentsBloc>().add(
                    LoadAssignmentDetailEvent(widget.assignmentId),
                  );
                }
              },
              icon: Icon(
                sub == null ? Icons.edit_note_rounded : Icons.edit_rounded,
              ),
              label: Text(
                sub == null
                    ? 'Bắt đầu làm bài'
                    : sub.status == 'DRAFT'
                    ? 'Tiếp tục làm bài'
                    : 'Sửa bài nộp',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentTile(AssignmentAttachmentModel att) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              att.name,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: 'Mở tài liệu',
            onPressed: att.url.isEmpty ? null : () => _openAttachment(att.url),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(String url) async {
    final uri = resolveAttachmentUrl(url);
    if (uri != null) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tài liệu này.')),
      );
    }
  }

  Widget _buildStudentSubmissionCard(
    AssignmentModel assignment,
    SubmissionModel sub,
  ) {
    final deadline = assignment.deadline == null
        ? null
        : DateTime.tryParse(assignment.deadline!);
    final canEdit =
        sub.status == 'RETURNED' ||
        sub.status == 'DRAFT' ||
        (sub.status != 'GRADED' &&
            sub.status != 'GRADED_PENDING' &&
            (deadline == null || DateTime.now().isBefore(deadline.toLocal())));
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sub.status == 'GRADED'
                      ? AppColors.success.withAlpha(25)
                      : sub.status == 'LATE'
                      ? AppColors.warning.withAlpha(25)
                      : AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sub.status == 'GRADED'
                      ? 'ĐÃ CHẤM ĐIỂM'
                      : sub.status == 'GRADED_PENDING'
                      ? 'CHỜ CÔNG BỐ ĐIỂM'
                      : sub.status == 'DRAFT'
                      ? 'BẢN NHÁP'
                      : sub.status == 'RETURNED'
                      ? 'CẦN LÀM LẠI'
                      : sub.status == 'LATE'
                      ? 'ĐÃ NỘP (MUỘN)'
                      : 'ĐÃ NỘP · CHỜ CHẤM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: sub.status == 'GRADED'
                        ? AppColors.success
                        : sub.status == 'LATE'
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
              ),
              if (sub.submittedAt.isNotEmpty)
                Text(
                  'Nộp lúc: ${sub.submittedAt.split("T")[0]}',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: AppColors.neutral500),
                ),
            ],
          ),
          if (sub.score != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.success, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm số: ${sub.score!.toStringAsFixed(1)} / ${assignment.maxScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        if (sub.gradedByName != null)
                          Text(
                            'Chấm bởi: ${sub.gradedByName}',
                            style: AppTextStyles.caption(context)
                                .copyWith(color: AppColors.neutral600),
                          ),
                        if (sub.gradedAt != null)
                          Text(
                            'Chấm ngày ${sub.gradedAt!.split('T').first}',
                            style: AppTextStyles.caption(context),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Nhận xét từ giáo viên:',
              style: AppTextStyles.caption(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              sub.feedback!,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.neutral700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (sub.content != null && sub.content!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Nội dung bài nộp:',
              style: AppTextStyles.caption(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(sub.content!, style: AppTextStyles.bodyMedium(context)),
          ],
          if (sub.fileUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tệp bài làm',
              style: AppTextStyles.caption(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            for (final file in sub.fileUrls)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text(file.name),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openAttachment(file.url),
              ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            label: Text(
              canEdit
                  ? sub.status == 'DRAFT'
                        ? 'Tiếp tục làm bài'
                        : 'Sửa bài nộp'
                  : 'Không thể sửa bài nộp',
            ),
            onPressed: canEdit
                ? () async {
                    final updated = await context.push<bool>(
                      '/assignments/${widget.assignmentId}/submit',
                    );
                    if (mounted && updated == true) {
                      context.read<AssignmentsBloc>().add(
                        LoadAssignmentDetailEvent(widget.assignmentId),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNotSubmittedCard(AssignmentModel assignment) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 48, color: AppColors.neutral400),
          const SizedBox(height: 10),
          Text(
            'Bạn chưa nộp bài tập này',
            style: AppTextStyles.bodyMedium(context)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy hoàn thành bài nộp trước hạn để không bị tính trễ hạn.',
            style: AppTextStyles.caption(context)
                .copyWith(color: AppColors.neutral500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Nộp Bài Tập Ngay',
            icon: Icons.send,
            onPressed: () {
              context.push('/assignments/${assignment.id}/submit');
            },
          ),
        ],
      ),
    );
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'SPEAKING':
        return 'Ghi âm phát âm (Speaking)';
      case 'WRITING':
        return 'Bài luận (Writing)';
      case 'PROJECT':
        return 'Dự án (Project)';
      default:
        return 'Bài tập về nhà (Homework)';
    }
  }
}
