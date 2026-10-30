import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppDatePicker extends StatefulWidget {
  final String? label;
  final String? hintText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const AppDatePicker({
    super.key,
    this.label,
    this.hintText = 'Chọn ngày',
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.enabled = true,
  });

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
  }

  @override
  void didUpdateWidget(covariant AppDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
      if (_selectedDate != null) {
        _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(1950);
    final last = widget.lastDate ?? DateTime(2050);
    final initial = _selectedDate ?? (now.isAfter(first) && now.isBefore(last) ? now : first);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.label(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: widget.enabled ? _pickDate : null,
          borderRadius: BorderRadius.circular(8),
          child: IgnorePointer(
            child: TextFormField(
              controller: _controller,
              validator: (_) => widget.validator?.call(_selectedDate),
              style: AppTextStyles.bodyLarge(context),
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
