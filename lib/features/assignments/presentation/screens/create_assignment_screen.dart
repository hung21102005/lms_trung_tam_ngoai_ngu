import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/linkified_text.dart';
import '../../domain/repositories/assignments_repository.dart';
import '../../data/models/assignment_model.dart';
import '../bloc/assignments_bloc.dart';
import '../bloc/assignments_event.dart';
import '../bloc/assignments_state.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;
  final String? assignmentId;

  const CreateAssignmentScreen({
    super.key,
    required this.classId,
    this.assignmentId,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '10');
  final List<PlatformFile> _selectedFiles = [];
  final List<AssignmentAttachmentModel> _existingAttachments = [];
  bool _isUploading = false;
  bool _isLoadingInitial = false;
  String? _loadError;

  String _selectedType = 'HOMEWORK';
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    if (widget.assignmentId != null) _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _isLoadingInitial = true;
      _loadError = null;
    });
    try {
      final assignment = await getIt<AssignmentsRepository>()
          .getAssignmentDetail(widget.assignmentId!);
      if (!mounted) return;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description ?? '';
      _maxScoreController.text = assignment.maxScore.toStringAsFixed(
        assignment.maxScore % 1 == 0 ? 0 : 1,
      );
      _selectedType = assignment.type;
      _selectedDeadline = assignment.deadline == null
          ? null
          : DateTime.tryParse(assignment.deadline!)?.toLocal();
      _existingAttachments
        ..clear()
        ..addAll(assignment.attachments);
    } catch (error) {
      if (mounted) {
        _loadError = 'Không tải được bài tập: $error';
      }
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
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
          'gif',
        ],
      );
      if (!mounted) return;
      for (final file in files) {
        final size =
            file.lengthSync() ??
            await file.length() ??
            (await file.readAsBytes()).length;
        if (size > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${file.name}: tệp phải nhỏ hơn 50 MB.')),
            );
          }
          continue;
        }
        if (!_selectedFiles.any((item) => item.name == file.name)) {
          _selectedFiles.add(file);
        }
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không chọn được tệp: $error')));
      }
    }
  }

  Future<void> _submit() async {
    if (_isUploading || !_formKey.currentState!.validate()) return;
    final maxScore = double.tryParse(_maxScoreController.text.trim());
    if (maxScore == null || maxScore < 1 || maxScore > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thang điểm phải từ 1 đến 100.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final attachments = _existingAttachments.map((e) => e.toJson()).toList();
      for (final file in _selectedFiles) {
        final bytes = await file.readAsBytes();
        if (bytes.length > 50 * 1024 * 1024) {
          throw Exception('${file.name} vượt quá giới hạn 50 MB.');
        }
        final uploaded = await getIt<AssignmentsRepository>().uploadAttachment(
          file.name,
          bytes,
        );
        attachments.add(uploaded.toJson());
      }
      if (!mounted) return;
      if (widget.assignmentId != null) {
        await getIt<AssignmentsRepository>().updateAssignment(
          widget.assignmentId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          deadline: _selectedDeadline?.toIso8601String(),
          maxScore: maxScore,
          attachments: attachments,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài tập.')));
        context.pop(true);
        return;
      }
      context.read<AssignmentsBloc>().add(
        CreateAssignmentEvent(
          classId: widget.classId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          type: _selectedType,
          deadline: _selectedDeadline?.toIso8601String(),
          maxScore: maxScore,
          attachments: attachments.isEmpty ? null : attachments,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được bài tập: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignmentId == null ? 'Giao bài tập mới' : 'Sửa bài tập',
        ),
      ),
      body: BlocConsumer<AssignmentsBloc, AssignmentsState>(
        listener: (context, state) {
          if (widget.assignmentId == null &&
              state is AssignmentOperationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (widget.assignmentId == null &&
              state is AssignmentsErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              widget.assignmentId == null && state is AssignmentsLoadingState;

          if (_isLoadingInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_loadError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!),
                  TextButton(
                    onPressed: _loadAssignment,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Thông tin bài tập', style: AppTextStyles.h4(context)),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _titleController,
                  label: 'Tiêu đề bài tập *',
                  hintText: 'Ví dụ: Speaking Practice: IELTS Part 2 cue card',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề bài tập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppDropdown<String>(
                  label: 'Loại bài tập',
                  value: _selectedType,
                  items: const [
                    AppDropdownItem(
                      value: 'HOMEWORK',
                      label: 'Bài tập về nhà (Homework)',
                    ),
                    AppDropdownItem(
                      value: 'SPEAKING',
                      label: 'Bài nói / Ghi âm (Speaking)',
                    ),
                    AppDropdownItem(
                      value: 'WRITING',
                      label: 'Bài viết / Luận (Writing)',
                    ),
                    AppDropdownItem(
                      value: 'PROJECT',
                      label: 'Dự án nhóm (Project)',
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),

                _buildScoreAndDeadline(context),
                if (widget.assignmentId != null && _selectedDeadline != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedDeadline = null),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Bỏ hạn nộp'),
                    ),
                  ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _descriptionController,
                  label: 'Yêu cầu & Hướng dẫn làm bài',
                  hintText: 'Mô tả chi tiết đề bài, các tiêu chí chấm điểm, số từ tối thiểu...',
                  maxLines: 5,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _descriptionController,
                  builder: (context, value, _) {
                    if (!RegExp(
                      r'https?://|www\.',
                      caseSensitive: false,
                    ).hasMatch(value.text)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xem trước mô tả',
                            style: AppTextStyles.label(context),
                          ),
                          const SizedBox(height: 6),
                          LinkifiedText(text: value.text),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Tài liệu hướng dẫn đính kèm (Tùy chọn)',
                  style: AppTextStyles.h4(context),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading || isLoading ? null : _pickFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Chọn tệp từ máy'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PDF, Word, Excel, PowerPoint, ảnh, TXT, ZIP hoặc RAR · tối đa 50 MB/tệp',
                ),
                for (final file in _existingAttachments)
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(file.name),
                    subtitle: const Text('Tệp đã đính kèm'),
                    trailing: IconButton(
                      tooltip: 'Bỏ tệp',
                      icon: const Icon(Icons.close),
                      onPressed: _isUploading || isLoading
                          ? null
                          : () => setState(
                              () => _existingAttachments.remove(file),
                            ),
                    ),
                  ),
                for (final file in _selectedFiles)
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(file.name),
                    subtitle: Text(
                      '${((file.lengthSync() ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                    ),
                    trailing: IconButton(
                      tooltip: 'Bỏ tệp',
                      icon: const Icon(Icons.close),
                      onPressed: _isUploading || isLoading
                          ? null
                          : () => setState(() => _selectedFiles.remove(file)),
                    ),
                  ),
                const SizedBox(height: 32),

                AppButton(
                  text: widget.assignmentId == null
                      ? 'Tạo & Giao Bài Tập'
                      : 'Lưu thay đổi',
                  icon: widget.assignmentId == null ? Icons.send : Icons.save,
                  isLoading: isLoading || _isUploading,
                  onPressed: isLoading || _isUploading ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreAndDeadline(BuildContext context) {
    final scoreField = AppTextField(
      controller: _maxScoreController,
      label: 'Thang điểm tối đa',
      hintText: '10',
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nhập điểm tối đa';
        }
        return null;
      },
    );
    final deadlineField = AppDatePicker(
      label: 'Hạn nộp bài (Deadline)',
      initialDate: _selectedDeadline,
      onDateSelected: (date) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            23,
            59,
            59,
          );
        });
      },
    );
    if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile) {
      return Column(
        children: [scoreField, const SizedBox(height: 16), deadlineField],
      );
    }
    return Row(
      children: [
        Expanded(child: scoreField),
        const SizedBox(width: 16),
        Expanded(child: deadlineField),
      ],
    );
  }
}
