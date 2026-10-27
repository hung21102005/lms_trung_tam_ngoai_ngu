import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/assignment_model.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';

class SubmissionReviewScreen extends StatefulWidget {
  final String assignmentId;
  final String studentId;
  final bool focusScore;

  const SubmissionReviewScreen({
    super.key,
    required this.assignmentId,
    required this.studentId,
    this.focusScore = false,
  });

  @override
  State<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends State<SubmissionReviewScreen> {
  SubmissionModel? _submission;
  StudentSubmissionItemModel? _student;
  String _assignmentTitle = '';
  double _maxScore = 10;
  bool _initialized = false;
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;
  String? _scoreError;
  bool _publishing = false;
  bool _returning = false;
  int _mobilePane = 0;

  @override
  void initState() {
    super.initState();
    _mobilePane = widget.focusScore ? 1 : 0;
    _scoreController = TextEditingController();
    _feedbackController = TextEditingController();
    _reload();
  }

  void _reload() {
    context.read<AssignmentsBloc>().add(
      LoadAssignmentSubmissionsEvent(widget.assignmentId),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _saveGrade() {
    final score = double.tryParse(
      _scoreController.text.trim().replaceAll(',', '.'),
    );
    if (score == null || !score.isFinite || score < 0 || score > _maxScore) {
      setState(() {
        _scoreError = 'Nhập điểm từ 0 đến ${_maxScore.toStringAsFixed(1)}';
      });
      return;
    }
    setState(() => _scoreError = null);
    context.read<AssignmentsBloc>().add(
      GradeSubmissionEvent(
        assignmentId: widget.assignmentId,
        submissionId: _submission!.id,
        score: score,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      ),
    );
  }

  Future<void> _publishResult() async {
    final submission = _submission;
    if (submission == null || _publishing) return;
    setState(() => _publishing = true);
    try {
      await getIt<AssignmentsRepository>().publishResult(submission.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã công bố điểm cho học viên.')),
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không công bố được điểm: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _requestRedo() async {
    final submission = _submission;
    final feedback = _feedbackController.text.trim();
    if (submission == null || _returning) return;
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập hướng dẫn để học viên làm lại.'),
        ),
      );
      return;
    }
    setState(() => _returning = true);
    try {
      await getIt<AssignmentsRepository>().returnSubmission(
        submission.id,
        feedback,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu làm lại cho học viên.')),
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không gửi được yêu cầu: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _returning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssignmentsBloc, AssignmentsState>(
      listener: (context, state) {
        if (state is AssignmentSubmissionsLoadedState &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AssignmentsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isGrading =
            state is AssignmentSubmissionsLoadedState && state.isGrading;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.focusScore
                  ? 'Xem bài làm và sửa điểm'
                  : 'Xem bài làm và chấm điểm',
            ),
          ),
          body: _buildBody(state, isGrading),
        );
      },
    );
  }

  Widget _buildBody(AssignmentsState state, bool isGrading) {
    if (state is AssignmentsInitialState || state is AssignmentsLoadingState) {
      return const LoadingWidget(message: 'Đang tải bài làm...');
    }
    if (state is AssignmentsErrorState) {
      return AppErrorWidget(message: state.message, onRetry: _reload);
    }
    if (state is! AssignmentSubmissionsLoadedState) {
      return const SizedBox.shrink();
    }
    StudentSubmissionItemModel? selected;
    for (final student in state.data.students) {
      if (student.studentId == widget.studentId) {
        selected = student;
        break;
      }
    }
    if (selected?.submission == null) {
      return const Center(child: Text('Học viên này chưa có bài nộp.'));
    }
    _student = selected;
    _submission = selected!.submission;
    _assignmentTitle = state.data.title;
    _maxScore = state.data.maxScore;
    if (!_initialized) {
      _scoreController.text = _submission!.score?.toString() ?? '';
      _feedbackController.text = _submission!.feedback ?? '';
      _initialized = true;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_assignmentTitle, style: AppTextStyles.h4(context)),
          const SizedBox(height: 4),
          Text(
            '${_student!.fullName} · ${_student!.userCode}',
            style: AppTextStyles.bodyMedium(context)
                .copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: 12),
          if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
              AdaptiveSize.mobile) ...[
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Bài làm'),
                    selected: _mobilePane == 0,
                    onSelected: (_) => setState(() => _mobilePane = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Chấm điểm'),
                    selected: _mobilePane == 1,
                    onSelected: (_) => setState(() => _mobilePane = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: KeyedSubtree(
                key: const ValueKey('submission-review-mobile'),
                child: _mobilePane == 0
                    ? _buildWorkPane()
                    : _buildGradingPane(isGrading),
              ),
            ),
          ] else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gradingPane = _buildGradingPane(isGrading);
                  final workPane = _buildWorkPane();
                  if (constraints.maxWidth >= 760) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: workPane),
                        const SizedBox(width: 16),
                        SizedBox(width: 350, child: gradingPane),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: workPane),
                      const SizedBox(height: 12),
                      SizedBox(height: 300, child: gradingPane),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkPane() {
    final content = _submission?.content?.trim() ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bài làm của học viên', style: AppTextStyles.h4(context)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.isNotEmpty)
                      SelectableText(
                        content,
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(height: 1.6),
                      )
                    else
                      const Text('Bài nộp không có nội dung văn bản.'),
                    if (_submission!.fileUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Tệp đính kèm', style: AppTextStyles.h4(context)),
                      const SizedBox(height: 10),
                      for (final file in _submission!.fileUrls)
                        _attachment(file),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachment(AssignmentAttachmentModel file) {
    final isImage =
        file.fileType.toUpperCase() == 'IMAGE' ||
        RegExp(
          r'\.(png|jpe?g|webp)(\?|$)',
          caseSensitive: false,
        ).hasMatch(file.url);
    final isAudio =
        file.fileType.toUpperCase() == 'AUDIO' ||
        RegExp(
          r'\.(mp3|m4a|wav)(\?|$)',
          caseSensitive: false,
        ).hasMatch(file.url);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isImage
                      ? Icons.image_outlined
                      : isAudio
                      ? Icons.audiotrack
                      : Icons.attach_file,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép liên kết tệp',
                  onPressed: file.url.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: file.url),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép liên kết tệp'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            if (file.url.isNotEmpty) SelectableText(file.url),
            if (isImage && file.url.startsWith('https://')) ...[
              const SizedBox(height: 10),
              Image.network(
                file.url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('Không tải được bản xem trước của ảnh.'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradingPane(bool isGrading) {
    if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Chấm điểm & nhận xét', style: AppTextStyles.h4(context)),
            const Divider(),
            const SizedBox(height: 8),
            AppTextField(
              controller: _scoreController,
              label: 'Điểm số / ${_maxScore.toStringAsFixed(1)}',
              autofocus: widget.focusScore,
              hintText: 'Ví dụ: 8.5',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_scoreError != null) setState(() => _scoreError = null);
              },
            ),
            if (_scoreError != null) ...[
              const SizedBox(height: 6),
              Text(
                _scoreError!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 18),
            AppTextField(
              controller: _feedbackController,
              label: 'Nhận xét cho học viên',
              hintText: 'Góp ý về bài làm và những điểm cần cải thiện...',
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            if (_submission?.status == 'GRADED') ...[
              Text(
                _submission!.resultPublishedAt == null
                    ? 'Điểm đã lưu, chưa công bố cho học viên.'
                    : 'Điểm đã được công bố.',
                style: AppTextStyles.caption(context),
              ),
              if (_submission!.resultPublishedAt == null)
                OutlinedButton.icon(
                  onPressed: _publishing || isGrading ? null : _publishResult,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(_publishing ? 'Đang công bố...' : 'Công bố điểm'),
                ),
            ],
            if (_submission?.status == 'SUBMITTED' ||
                _submission?.status == 'LATE')
              OutlinedButton.icon(
                onPressed: isGrading || _returning ? null : _requestRedo,
                icon: const Icon(Icons.replay_outlined),
                label: Text(_returning ? 'Đang gửi...' : 'Yêu cầu làm lại'),
              ),
            if (_submission?.status == 'RETURNED')
              const Text('Đang chờ học viên nộp lại bài.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: isGrading || _submission?.status == 'RETURNED'
                  ? null
                  : _saveGrade,
              icon: isGrading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isGrading ? 'Đang lưu...' : 'Lưu điểm và nhận xét'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chấm điểm & nhận xét', style: AppTextStyles.h4(context)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _scoreController,
                      label: 'Điểm số / ${_maxScore.toStringAsFixed(1)}',
                      autofocus: widget.focusScore,
                      hintText: 'Ví dụ: 8.5',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        if (_scoreError != null) {
                          setState(() => _scoreError = null);
                        }
                      },
                    ),
                    if (_scoreError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _scoreError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _feedbackController,
                      label: 'Nhận xét cho học viên',
                      hintText:
                          'Góp ý về bài làm và những điểm cần cải thiện...',
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_submission?.status == 'GRADED') ...[
              Text(
                _submission!.resultPublishedAt == null
                    ? 'Điểm đã lưu, chưa công bố cho học viên.'
                    : 'Điểm đã được công bố.',
                style: AppTextStyles.caption(context),
              ),
              const SizedBox(height: 8),
              if (_submission!.resultPublishedAt == null)
                OutlinedButton.icon(
                  onPressed: _publishing || isGrading ? null : _publishResult,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(_publishing ? 'Đang công bố...' : 'Công bố điểm'),
                ),
            ],
            if (_submission?.status == 'SUBMITTED' ||
                _submission?.status == 'LATE') ...[
              OutlinedButton.icon(
                onPressed: isGrading || _returning ? null : _requestRedo,
                icon: const Icon(Icons.replay_outlined),
                label: Text(_returning ? 'Đang gửi...' : 'Yêu cầu làm lại'),
              ),
              const SizedBox(height: 8),
            ],
            if (_submission?.status == 'RETURNED')
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Đang chờ học viên nộp lại bài.'),
              ),
            FilledButton.icon(
              onPressed: isGrading || _submission?.status == 'RETURNED'
                  ? null
                  : _saveGrade,
              icon: isGrading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isGrading ? 'Đang lưu...' : 'Lưu điểm và nhận xét'),
            ),
          ],
        ),
      ),
    );
  }
}
