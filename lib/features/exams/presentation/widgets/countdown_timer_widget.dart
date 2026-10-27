import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime startedAt;
  final int durationMinutes;
  final VoidCallback onTimeExpired;

  const CountdownTimerWidget({
    super.key,
    required this.startedAt,
    required this.durationMinutes,
    required this.onTimeExpired,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        widget.onTimeExpired();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _calculateRemainingTime() {
    final deadline = widget.startedAt.add(Duration(minutes: widget.durationMinutes));
    final now = DateTime.now();
    final diff = deadline.difference(now).inSeconds;
    _remainingSeconds = diff > 0 ? diff : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds < 300; // Dưới 5 phút

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? AppColors.error : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: isUrgent ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(_remainingSeconds),
            style: AppTextStyles.h4(context).copyWith(
              color: isUrgent ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
