import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';

class CreateExamScreen extends StatefulWidget {
  final String? classId;

  const CreateExamScreen({super.key, this.classId});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _totalPointsController = TextEditingController(text: '10');
  final _passPercentageController = TextEditingController(text: '50');
  final _maxAttemptsController = TextEditingController(text: '1');

  bool _shuffleQuestions = false;
  String _selectedStatus = 'PUBLISHED';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _totalPointsController.dispose();
    _passPercentageController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text) ?? 45;
    final totalPoints = double.tryParse(_totalPointsController.text) ?? 10.0;
    final passPercentage =
        double.tryParse(_passPercentageController.text) ?? 50.0;
    final maxAttempts = int.tryParse(_maxAttemptsController.text) ?? 1;

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'durationMinutes': duration,
      'totalPoints': totalPoints,
      'passPercentage': passPercentage,
      'maxAttempts': maxAttempts,
      'shuffleQuestions': _shuffleQuestions,
      'status': _selectedStatus,
      'classId': widget.classId,
    };

    context.read<ExamsBloc>().add(CreateExamEvent(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Đề Thi / Kiểm Tra')),
      body: BlocConsumer<ExamsBloc, ExamsState>(
        listener: (context, state) {
          if (state is ExamActionSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(true);
          } else if (state is ExamsErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ExamsLoadingState;

          if (MediaQuery.sizeOf(context).width < 1024) {
            return _buildMobileForm(isLoading);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin đề thi',
                          style: AppTextStyles.h4(context),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _titleController,
                          label: 'Tiêu đề đề thi / bài kiểm tra *',
                          hintText: 'Ví dụ: Kiểm tra giữa kỳ - IELTS Reading & Writing',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tiêu đề bài thi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _descriptionController,
                          label: 'Mô tả & Hướng dẫn làm bài',
                          hintText: 'Quy định làm bài thi, lưu ý thiết bị và kết nối mạng...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _durationController,
                                label: 'Thời gian (phút) *',
                                hintText: '45',
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Nhập thời gian'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _totalPointsController,
                                label: 'Thang điểm tối đa *',
                                hintText: '10',
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Nhập thang điểm'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _passPercentageController,
                                label: '% Điểm đạt (Pass) *',
                                hintText: '50',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                controller: _maxAttemptsController,
                                label: 'Số lần thi tối đa *',
                                hintText: '1',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        AppDropdown<String>(
                          label: 'Trạng thái phát hành đề thi',
                          value: _selectedStatus,
                          items: const [
                            AppDropdownItem(
                              value: 'PUBLISHED',
                              label: 'Mở thi ngay (Published)',
                            ),
                            AppDropdownItem(
                              value: 'DRAFT',
                              label: 'Lưu bản nháp (Draft)',
                            ),
                            AppDropdownItem(
                              value: 'CLOSED',
                              label: 'Đóng thi (Closed)',
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Trộn ngẫu nhiên câu hỏi (Shuffle)',
                          ),
                          subtitle: const Text(
                            'Thứ tự câu hỏi sẽ được xáo ngẫu nhiên cho từng học viên',
                          ),
                          value: _shuffleQuestions,
                          onChanged: (val) =>
                              setState(() => _shuffleQuestions = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    text: 'Tạo & Phát Hành Đề Thi',
                    icon: Icons.publish,
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                MobileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileStatusPill(
                        label: 'Bài kiểm tra mới',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thiết lập đề thi',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tạo thông tin bài thi và cấu hình điều kiện làm bài cho học viên.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MobileTokens.sectionGap),
                Text(
                  'Nội dung',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                MobileSectionCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề bài thi *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.trim().isEmpty == true
                            ? 'Nhập tiêu đề bài thi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả và hướng dẫn',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MobileTokens.sectionGap),
                Text(
                  'Thời gian và chấm điểm',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                MobileSectionCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian (phút) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final number = int.tryParse(value?.trim() ?? '');
                          return number == null || number <= 0
                              ? 'Thời gian phải lớn hơn 0'
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _totalPointsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Thang điểm tối đa *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          return number == null || number <= 0
                              ? 'Thang điểm phải lớn hơn 0'
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passPercentageController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Điểm đạt (%) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          return number == null || number < 0 || number > 100
                              ? 'Nhập tỷ lệ từ 0 đến 100'
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _maxAttemptsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lần thi tối đa *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final number = int.tryParse(value?.trim() ?? '');
                          return number == null || number <= 0
                              ? 'Số lần thi phải lớn hơn 0'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MobileTokens.sectionGap),
                Text(
                  'Phát hành',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                MobileSectionCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PUBLISHED',
                            child: Text('Mở thi ngay'),
                          ),
                          DropdownMenuItem(
                            value: 'DRAFT',
                            child: Text('Lưu bản nháp'),
                          ),
                          DropdownMenuItem(
                            value: 'CLOSED',
                            child: Text('Đóng thi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Trộn câu hỏi'),
                        subtitle: const Text(
                          'Thứ tự khác nhau cho từng học viên',
                        ),
                        value: _shuffleQuestions,
                        onChanged: (value) =>
                            setState(() => _shuffleQuestions = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _selectedStatus == 'DRAFT' ? 'Lưu bản nháp' : 'Tạo đề thi',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
