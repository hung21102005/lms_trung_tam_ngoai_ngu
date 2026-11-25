import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DeadlineCountdownWidget extends StatelessWidget {
  final String? deadline;

  const DeadlineCountdownWidget({super.key, this.deadline});

  @override
  Widget build(BuildContext context) {
    if (deadline == null || deadline!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive,
              size: 12,
              color: AppColors.textSecondary(context),
            ),
            const SizedBox(width: 4),
            Text(
              'Không giới hạn',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textBody(context),
              ),
            ),
          ],
        ),
      );
    }

    DateTime? deadlineDate;
    try {
      deadlineDate = DateTime.parse(deadline!);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final difference = deadlineDate.difference(now);
    final isExpired = difference.isNegative;

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.errorBg(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.errorFg(context).withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off, size: 12, color: AppColors.errorFg(context)),
            const SizedBox(width: 4),
            Text(
              'Đã hết hạn',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.errorFg(context),
              ),
            ),
          ],
        ),
      );
    }

    // Remaining duration formatting
    String text;
    Color color;
    if (difference.inDays > 0) {
      text = 'Còn ${difference.inDays} ngày ${difference.inHours % 24} giờ';
      color = difference.inDays > 2
          ? AppColors.primaryOf(context)
          : AppColors.warningFg(context);
    } else if (difference.inHours > 0) {
      text = 'Còn ${difference.inHours} giờ ${difference.inMinutes % 60} phút';
      color = AppColors.warningFg(context);
    } else {
      text = 'Còn ${difference.inMinutes} phút';
      color = AppColors.errorFg(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
