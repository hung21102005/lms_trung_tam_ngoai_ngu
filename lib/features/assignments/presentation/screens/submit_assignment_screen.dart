import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/attachment_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/linkified_text.dart';
import '../../data/models/assignment_model.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';
import '../widgets/audio_recorder_widget.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;

  const SubmitAssignmentScreen({super.key, required this.assignmentId});

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _textController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  final List<AssignmentAttachmentModel> _existingFiles = [];
  String? _recordedAudioName;
  Uint8List? _recordedAudioBytes;
  bool _initialized = false;
  bool _isUploading = false;
  bool _savedDraft = false;
  DateTime? _lastSavedAt;
  final AudioPlayer _savedAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSubscription;
  String? _playingAudio;

  @override
  void initState() {
    super.initState();
    _playerSubscription = _savedAudioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted && state != PlayerState.playing) {
        setState(() => _playingAudio = null);
      }
    });
    context.read<AssignmentsBloc>().add(
      LoadAssignmentDetailEvent(widget.assignmentId),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _playerSubscription?.cancel();
    unawaited(_savedAudioPlayer.dispose());
    super.dispose();
  }

  void _initializeSubmission(AssignmentModel assignment) {
    if (_initialized) return;
    _initialized = true;
    final submission = assignment.mySubmission;
    if (submission == null) return;
    _savedDraft = submission.status == 'DRAFT';
    _lastSavedAt = DateTime.tryParse(submission.updatedAt ?? '');
    _textController.text = submission.content ?? '';
    _existingFiles.addAll(submission.fileUrls);
  }

  bool _canEdit(AssignmentModel assignment) {
    final submission = assignment.mySubmission;
    if (submission == null) return true;
    if (submission.status == 'GRADED' ||
        submission.status == 'GRADED_PENDING') {
      return false;
    }
    if (submission.status == 'RETURNED' || submission.status == 'DRAFT') {
      return true;
    }
    final deadline = assignment.deadline == null
        ? null
        : DateTime.tryParse(assignment.deadline!);
    return deadline == null || DateTime.now().isBefore(deadline.toLocal());
  }

  Future<void> _pickFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'zip',
          'rar',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'mp3',
          'm4a',
          'wav',
        ],
      );
      if (!mounted) return;
      for (final file in files) {
        final size =
            file.lengthSync() ??
            await file.length() ??
            (await file.readAsBytes()).length;
        if (size > 50 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name}: tệp phải nhỏ hơn 50 MB.')),
          );
          continue;
        }
        if (!_selectedFiles.any((item) => item.name == file.name) &&
            !_existingFiles.any((item) => item.name == file.name)) {
          _selectedFiles.add(file);
        }
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không chọn được tệp: $error')));
      }
    }
  }

  bool _isAudio(AssignmentAttachmentModel file) =>
      file.fileType.toUpperCase() == 'AUDIO' ||
      RegExp(r'\.(mp3|m4a|wav|ogg)$', caseSensitive: false).hasMatch(file.name);

  Future<void> _playSavedAudio(AssignmentAttachmentModel file) async {
    final uri = resolveAttachmentUrl(file.url);
    if (uri == null) return;
    try {
      if (_playingAudio == file.url) {
        await _savedAudioPlayer.stop();
        if (mounted) setState(() => _playingAudio = null);
      } else {
        await _savedAudioPlayer.play(UrlSource(uri.toString()));
        if (mounted) setState(() => _playingAudio = file.url);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không phát được bản ghi: $error')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _uploadPending() async {
    final repository = getIt<AssignmentsRepository>();
    if (_recordedAudioBytes != null) {
      final uploaded = await repository.uploadAttachment(
        _recordedAudioName!,
        _recordedAudioBytes!,
      );
      _existingFiles.add(
        AssignmentAttachmentModel(
          name: uploaded.name,
          url: uploaded.url,
          fileType: 'AUDIO',
          size: uploaded.size,
        ),
      );
      _recordedAudioBytes = null;
    }
    for (final file in List<PlatformFile>.of(_selectedFiles)) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception('${file.name} vượt quá giới hạn 50 MB.');
      }
      final uploaded = await repository.uploadAttachment(file.name, bytes);
      _existingFiles.add(uploaded);
      _selectedFiles.remove(file);
    }
    if (mounted) setState(() {});
    return _existingFiles.map((file) => file.toJson()).toList();
  }

  Future<void> _saveDraft(AssignmentModel assignment) async {
    if (_isUploading || !_canEdit(assignment)) return;
    setState(() => _isUploading = true);
    try {
      final files = await _uploadPending();
      final saved = await getIt<AssignmentsRepository>().saveDraft(
        widget.assignmentId,
        content: _textController.text.trim(),
        fileUrls: files,
      );
      if (!mounted) return;
      setState(() {
        _savedDraft = true;
        _lastSavedAt =
            DateTime.tryParse(saved.updatedAt ?? '') ?? DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bản nháp trên hệ thống.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được bản nháp: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  bool _canSaveDraft(AssignmentModel assignment) {
    final deadline = DateTime.tryParse(assignment.deadline ?? '');
    return deadline == null || DateTime.now().isBefore(deadline.toLocal());
  }

  Future<void> _submit(AssignmentModel assignment) async {
    if (_isUploading || !_canEdit(assignment)) return;
    final type = assignment.type.toUpperCase();
    final supportsText = type != 'SPEAKING';
    final supportsAudio = type != 'WRITING';
    final content = supportsText ? _textController.text.trim() : '';
    final hasFiles = _existingFiles.isNotEmpty || _selectedFiles.isNotEmpty;
    final hasAudio = supportsAudio && _recordedAudioBytes != null;
    if (content.isEmpty && !hasFiles && !hasAudio) {
      final message = type == 'SPEAKING'
          ? 'Vui lòng ghi âm hoặc đính kèm tệp bài nói.'
          : type == 'WRITING'
          ? 'Vui lòng nhập bài viết hoặc đính kèm tệp.'
          : 'Vui lòng nhập nội dung, ghi âm hoặc đính kèm tệp.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final files = await _uploadPending();
      final submitted = await getIt<AssignmentsRepository>().submitAssignment(
        widget.assignmentId,
        content: content.isEmpty ? null : content,
        fileUrls: files.isEmpty ? null : files,
      );
      if (!mounted) return;
      final submittedAt = DateTime.tryParse(submitted.submittedAt)?.toLocal();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.task_alt, color: AppColors.success, size: 52),
          title: Text(
            submitted.status == 'LATE'
                ? 'Đã nộp bài muộn'
                : 'Nộp bài thành công',
          ),
          content: Text(
            submittedAt == null
                ? 'Bài làm đã được lưu trên hệ thống.'
                : 'Bài làm đã được lưu lúc ${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')} ngày ${submittedAt.day}/${submittedAt.month}/${submittedAt.year}.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Xem bài tập'),
            ),
          ],
        ),
      );
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không nộp được bài: $error')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nộp bài tập')),
      body: BlocConsumer<AssignmentsBloc, AssignmentsState>(
        listener: (context, state) {
          if (state is AssignmentsErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AssignmentsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AssignmentsErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<AssignmentsBloc>().add(
                LoadAssignmentDetailEvent(widget.assignmentId),
              ),
            );
          }
          if (state is! AssignmentDetailLoadedState) {
            return const SizedBox.shrink();
          }
          final assignment = state.assignment;
          _initializeSubmission(assignment);
          final isEditing = assignment.mySubmission != null && !_savedDraft;
          final canEdit = _canEdit(assignment);
          final busy = state.isSubmitting || _isUploading;
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, size) {
                    if (size.maxWidth >= 900) {
                      return Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _buildAssignmentBrief(assignment),
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: _buildForm(assignment, canEdit)),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAssignmentBrief(assignment),
                          const SizedBox(height: 18),
                          _buildForm(assignment, canEdit, embedded: true),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_lastSavedAt != null)
                        Text(
                          'Bản nháp đã lưu: ${_lastSavedAt!.toLocal().hour.toString().padLeft(2, '0')}:${_lastSavedAt!.toLocal().minute.toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption(context),
                        ),
                      if (assignment.mySubmission == null ||
                          assignment.mySubmission!.status == 'DRAFT' ||
                          _savedDraft)
                        OutlinedButton.icon(
                          onPressed:
                              busy || !canEdit || !_canSaveDraft(assignment)
                              ? null
                              : () => _saveDraft(assignment),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Lưu bản nháp'),
                        ),
                      AppButton(
                        text: isEditing ? 'Cập nhật bài nộp' : 'Nộp bài tập',
                        icon: Icons.send,
                        isLoading: busy,
                        onPressed: busy || !canEdit
                            ? null
                            : () => _submit(assignment),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentBrief(AssignmentModel assignment) {
    final deadline = DateTime.tryParse(assignment.deadline ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu bài tập', style: AppTextStyles.h4(context)),
            const SizedBox(height: 12),
            Text(assignment.title, style: AppTextStyles.h4(context)),
            const SizedBox(height: 8),
            Text(
              '${assignment.courseName ?? 'Khóa học'} · ${assignment.className ?? 'Lớp học'} · ${assignment.createdByName ?? 'Giảng viên'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Hạn nộp: ${deadline == null ? 'Không giới hạn' : '${deadline.toLocal().day}/${deadline.toLocal().month}/${deadline.toLocal().year}'} · Thang ${assignment.maxScore.toStringAsFixed(1)} điểm',
            ),
            const Divider(height: 28),
            LinkifiedText(
              text: assignment.description?.isNotEmpty == true
                  ? assignment.description!
                  : 'Giảng viên chưa thêm hướng dẫn chi tiết.',
            ),
            if (assignment.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Tài liệu hướng dẫn', style: AppTextStyles.h4(context)),
              for (final file in assignment.attachments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(file.name),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = resolveAttachmentUrl(file.url);
                    if (uri == null ||
                        !await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không mở được tài liệu.'),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    AssignmentModel assignment,
    bool canEdit, {
    bool embedded = false,
  }) {
    final type = assignment.type.toUpperCase();
    final showAudio =
        type == 'SPEAKING' || type == 'HOMEWORK' || type == 'PROJECT';
    final showText =
        type == 'WRITING' || type == 'HOMEWORK' || type == 'PROJECT';
    return ListView(
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
      children: [
        Text('Bài làm của bạn', style: AppTextStyles.h4(context)),
        const SizedBox(height: 6),
        Text(
          _typeInstruction(type),
          style: AppTextStyles.bodyMedium(context)
              .copyWith(color: AppColors.neutral600),
        ),
        if (!canEdit) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: const Text(
              'Bài đã được chấm hoặc đã hết hạn. Bạn chỉ có thể xem bài đã nộp.',
            ),
          ),
        ],
        if (showAudio) ...[
          const SizedBox(height: 24),
          Text('Ghi âm bài làm', style: AppTextStyles.h4(context)),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: !canEdit,
            child: AudioRecorderWidget(
              onAudioRecorded: (name, bytes, _) => setState(() {
                _recordedAudioName = name;
                _recordedAudioBytes = bytes;
              }),
              onReset: () => setState(() {
                _recordedAudioName = null;
                _recordedAudioBytes = null;
              }),
            ),
          ),
        ],
        if (showText) ...[
          const SizedBox(height: 24),
          Text(
            type == 'WRITING' ? 'Nội dung bài viết' : 'Nội dung bài làm',
            style: AppTextStyles.h4(context),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _textController,
            hintText: 'Nhập nội dung bài làm tại đây...',
            maxLines: 10,
            readOnly: !canEdit,
          ),
        ],
        const SizedBox(height: 24),
        Text('Tệp bài làm đính kèm', style: AppTextStyles.h4(context)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: canEdit && !_isUploading ? _pickFiles : null,
            icon: const Icon(Icons.attach_file),
            label: const Text('Chọn tệp từ máy'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          type == 'SPEAKING'
              ? 'Tệp âm thanh, PDF, Word, TXT, ZIP, RAR hoặc ảnh · tối đa 50 MB/tệp'
              : 'PDF, Word, Excel, PowerPoint, ảnh, TXT, ZIP, RAR hoặc âm thanh · tối đa 50 MB/tệp',
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.neutral600),
        ),
        for (final file in _existingFiles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(file.name),
            subtitle: Text(
              _isAudio(file) ? 'Bản ghi âm đã lưu' : 'Tệp trong bài làm',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAudio(file))
                  IconButton(
                    tooltip: _playingAudio == file.url
                        ? 'Dừng nghe'
                        : 'Nghe lại',
                    icon: Icon(
                      _playingAudio == file.url ? Icons.stop : Icons.play_arrow,
                    ),
                    onPressed: () => _playSavedAudio(file),
                  ),
                if (canEdit)
                  IconButton(
                    tooltip: 'Bỏ tệp',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() => _existingFiles.remove(file)),
                  ),
              ],
            ),
          ),
        for (final file in _selectedFiles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(file.name),
            subtitle: Text(
              '${((file.lengthSync() ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
            ),
            trailing: IconButton(
              tooltip: 'Bỏ tệp',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedFiles.remove(file)),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _typeInstruction(String type) {
    switch (type) {
      case 'SPEAKING':
        return 'Ghi âm trực tiếp hoặc đính kèm tệp bài nói trong cùng trang.';
      case 'WRITING':
        return 'Viết nội dung trực tiếp hoặc đính kèm tệp bài viết.';
      case 'PROJECT':
        return 'Bạn có thể nhập nội dung, ghi âm và đính kèm tệp dự án.';
      default:
        return 'Bạn có thể nhập nội dung, ghi âm hoặc đính kèm tệp bài làm.';
    }
  }
}
