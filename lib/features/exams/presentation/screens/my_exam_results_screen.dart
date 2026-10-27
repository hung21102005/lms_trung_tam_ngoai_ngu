import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/exams_bloc.dart';
import '../bloc/exams_event.dart';
import '../bloc/exams_state.dart';
import '../../data/models/exam_model.dart';

class MyExamResultsScreen extends StatefulWidget {
  const MyExamResultsScreen({super.key});

  @override
  State<MyExamResultsScreen> createState() => _MyExamResultsScreenState();
}

class _MyExamResultsScreenState extends State<MyExamResultsScreen> {
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      context.read<ExamsBloc>().add(const LoadMyExamResultsEvent());

  @override
  Widget build(BuildContext context) {
    final isMobile =
        AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả bài kiểm tra'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: BlocBuilder<ExamsBloc, ExamsState>(
        builder: (context, state) {
          if (state is ExamsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExamsErrorState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            );
          }
          if (state is! MyExamResultsLoadedState) {
            return const SizedBox.shrink();
          }
          return ListView(
            key: isMobile ? const ValueKey('my-exam-results-mobile') : null,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
            children: [
              if (isMobile) ...[
                const Text(
                  'Kết quả của tôi',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.attempts.length} lượt thi',
                  style: const TextStyle(color: AppColors.neutral600),
                ),
                const SizedBox(height: MobileTokens.sectionGap),
              ],
              if (state.attempts.isEmpty)
                const MobileSectionCard(
                  child: Text('Bạn chưa có kết quả bài kiểm tra nào.'),
                ),
              for (final attempt in state.attempts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAttemptCard(attempt),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttemptCard(ExamAttemptModel attempt) {
    final isGraded = attempt.status == 'GRADED' && attempt.score != null;
    return MobileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attempt.examTitle ?? 'Bài kiểm tra',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (attempt.className?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              attempt.className!,
              style: const TextStyle(color: AppColors.neutral600),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            isGraded
                ? '${attempt.score!.toStringAsFixed(1)} / ${attempt.maxScore.toStringAsFixed(1)} điểm'
                : attempt.status == 'IN_PROGRESS'
                ? 'Đang làm bài'
                : 'Đang chờ chấm điểm',
            style: TextStyle(
              color: isGraded ? AppColors.success : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lượt ${attempt.attemptNumber}',
            style: const TextStyle(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}
