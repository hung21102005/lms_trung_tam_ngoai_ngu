import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/exam_model.dart';

class EssayQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool readOnly;

  const EssayQuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerChanged,
    this.readOnly = false,
  });

  @override
  State<EssayQuestionWidget> createState() => _EssayQuestionWidgetState();
}

class _EssayQuestionWidgetState extends State<EssayQuestionWidget> {
  late TextEditingController _controller;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedAnswer?.toString() ?? '';
    _controller = TextEditingController(text: initial);
    _wordCount = _countWords(initial);
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void didUpdateWidget(covariant EssayQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      final current = widget.selectedAnswer?.toString() ?? '';
      if (_controller.text != current) {
        _controller.text = current;
        _wordCount = _countWords(current);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.prompt,
          style: AppTextStyles.h4(context).copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Bài làm tự luận:',
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_wordCount từ',
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        AppTextField(
          controller: _controller,
          hintText: 'Nhập nội dung bài luận / câu trả lời tự luận tại đây...',
          maxLines: 12,
          readOnly: widget.readOnly,
          onChanged: (val) {
            setState(() {
              _wordCount = _countWords(val);
            });
            widget.onAnswerChanged(val);
          },
        ),
      ],
    );
  }
}
