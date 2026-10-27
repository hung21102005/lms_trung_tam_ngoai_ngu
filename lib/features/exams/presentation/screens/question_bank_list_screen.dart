import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../../data/models/exam_model.dart';

class QuestionBankListScreen extends StatefulWidget {
  const QuestionBankListScreen({super.key});

  @override
  State<QuestionBankListScreen> createState() => _QuestionBankListScreenState();
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
                context.read<ExamsBloc>().add(CreateQuestionBankEvent(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      language: 'EN',
                      level: levelCtrl.text.trim(),
                    ));
                Navigator.pop(ctx);
                _loadBanks();
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBankDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo ngân hàng'),
      ),
      body: BlocBuilder<ExamsBloc, ExamsState>(
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const LoadingWidget(message: 'Đang tải ngân hàng câu hỏi...');
          }

          if (state is ExamsErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: _loadBanks,
            );
          }

          if (state is QuestionBanksLoadedState) {
            final banks = state.banks;

            if (banks.isEmpty) {
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
                return _buildBankCard(bank);
              },
            );
          }

          return const SizedBox.shrink();
        },
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
                child: const Icon(Icons.quiz, color: AppColors.primary, size: 24),
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
                        style: AppTextStyles.caption(context).copyWith(color: AppColors.neutral600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.neutral600),
            ),
          ],
        ],
      ),
    );
  }
}
