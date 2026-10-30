import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/exam_model.dart';

class MultipleChoiceQuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool readOnly;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.prompt.isNotEmpty) ...[
          Text(
            question.prompt,
            style: AppTextStyles.h4(context).copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
        ],

        if (question.audioUrl != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đoạn băng ghi âm nghe câu hỏi',
                    style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Phát audio'),
                ),
              ],
            ),
          ),
        ],

        ...options.map((opt) {
          final isSelected = selectedAnswer != null &&
              (selectedAnswer == opt.id ||
                  (selectedAnswer is List && selectedAnswer.contains(opt.id)));

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: readOnly
                  ? null
                  : () {
                      onAnswerChanged(opt.id);
                    },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.neutral100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.neutral300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt.id,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.neutral700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt.text,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: isSelected ? AppColors.primary : null,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
