import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../../data/models/exam_model.dart';

class QuestionBankListScreen extends StatefulWidget {
  const QuestionBankListScreen({super.key});

  @override
  State<QuestionBankListScreen> createState() => _QuestionBankListScreenState();
}

class _MobileCreateBankSheet extends StatefulWidget {
  const _MobileCreateBankSheet({required this.onSubmit});

  final void Function(String title, String description, String level) onSubmit;

  @override
  State<_MobileCreateBankSheet> createState() => _MobileCreateBankSheetState();
}

class _MobileCreateBankSheetState extends State<_MobileCreateBankSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _levelController = TextEditingController(text: 'IELTS');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _levelController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.sizeOf(context).height * 0.9 -
                      MediaQuery.viewInsetsOf(context).bottom)
                  .clamp(120.0, double.infinity),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(
                'Tạo ngân hàng câu hỏi',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên ngân hàng *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Nhập tên ngân hàng'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _levelController,
                      decoration: const InputDecoration(
                        labelText: 'Trình độ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('Tạo ngân hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionBankListScreenState extends State<QuestionBankListScreen> {
  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  void _loadBanks() {
    context.read<ExamsBloc>().add(const LoadQuestionBanksEvent());
  }

  void _showCreateBankDialog() {
    if (MediaQuery.sizeOf(context).width < 1024) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _MobileCreateBankSheet(
          onSubmit: (title, description, level) {
            context.read<ExamsBloc>().add(
              CreateQuestionBankEvent(
                title: title,
                description: description,
                language: 'EN',
                level: level,
              ),
            );
          },
        ),
      );
      return;
    }
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: 'IELTS');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Ngân Hàng Câu Hỏi Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleCtrl,
              label: 'Tên ngân hàng câu hỏi *',
              hintText: 'Ví dụ: IELTS Reading & Vocabulary Band 6.5+',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: descCtrl,
              label: 'Mô tả',
              hintText: 'Mô tả chuyên đề hoặc kỹ năng...',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: levelCtrl,
              label: 'Trình độ / Level',
              hintText: 'IELTS, B2, TOEIC...',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                context.read<ExamsBloc>().add(
                  CreateQuestionBankEvent(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    language: 'EN',
                    level: levelCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tạo ngân hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân Hàng Câu Hỏi & Đề Thi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBanks),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBankDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo ngân hàng'),
      ),
      body: BlocConsumer<ExamsBloc, ExamsState>(
        listener: (context, state) {
          if (state is ExamActionSuccessState) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            _loadBanks();
          }
        },
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const LoadingWidget(
              message: 'Đang tải ngân hàng câu hỏi...',
            );
          }

          if (state is ExamsErrorState) {
            if (MediaQuery.sizeOf(context).width < 1024) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MobileSectionCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được ngân hàng câu hỏi: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                        TextButton.icon(
                          onPressed: _loadBanks,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AppErrorWidget(message: state.message, onRetry: _loadBanks);
          }

          if (state is QuestionBanksLoadedState) {
            final banks = state.banks;

            if (banks.isEmpty) {
              if (MediaQuery.sizeOf(context).width < 1024) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MobileSectionCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Chưa có ngân hàng câu hỏi'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _showCreateBankDialog,
                            child: const Text('Tạo ngân hàng'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return EmptyStateWidget(
                title: 'Chưa có ngân hàng câu hỏi',
                description: 'Hãy tạo ngân hàng câu hỏi đầu tiên để thiết kế đề thi cho học viên.',
                icon: Icons.source_outlined,
                buttonText: 'Tạo ngân hàng câu hỏi',
                onButtonPressed: _showCreateBankDialog,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banks.length,
              itemBuilder: (context, index) {
                final bank = banks[index];
                return MediaQuery.sizeOf(context).width < 1024
                    ? _buildMobileBankCard(bank)
                    : _buildBankCard(bank);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMobileBankCard(QuestionBankModel bank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MobileSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bank.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MobileStatusPill(
                  label: '${bank.questionCount} câu hỏi',
                  color: AppColors.primary,
                ),
                if (bank.level?.isNotEmpty == true)
                  MobileStatusPill(
                    label: bank.level!,
                    color: AppColors.secondary,
                  ),
              ],
            ),
            if (bank.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(bank.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(QuestionBankModel bank) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bank.title, style: AppTextStyles.h4(context)),
                    if (bank.level != null)
                      Text(
                        'Trình độ: ${bank.level}',
                        style: AppTextStyles.caption(context)
                            .copyWith(color: AppColors.neutral600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bank.questionCount} câu hỏi',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (bank.description != null && bank.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bank.description!,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(color: AppColors.neutral600),
            ),
          ],
        ],
      ),
    );
  }
}
