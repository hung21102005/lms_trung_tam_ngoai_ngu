import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/exam_model.dart';

class FillBlankQuestionWidget extends StatefulWidget {
  final QuestionModel question;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool readOnly;

  const FillBlankQuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerChanged,
    this.readOnly = false,
  });

  @override
  State<FillBlankQuestionWidget> createState() => _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedAnswer?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant FillBlankQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      final currentText = widget.selectedAnswer?.toString() ?? '';
      if (_controller.text != currentText) {
        _controller.text = currentText;
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
        const SizedBox(height: 24),

        Text(
          'Nhập câu trả lời của bạn vào ô bên dưới:',
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),

        AppTextField(
          controller: _controller,
          hintText: 'Nhập từ / cụm từ điền vào chỗ trống...',
          readOnly: widget.readOnly,
          onChanged: (val) {
            widget.onAnswerChanged(val.trim());
          },
        ),
      ],
    );
  }
}
