import 'package:flutter/material.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../assignments/domain/repositories/assignments_repository.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../exams/domain/repositories/exams_repository.dart';

class StudentGradebookView extends StatefulWidget {
  const StudentGradebookView({super.key});

  @override
  State<StudentGradebookView> createState() => _StudentGradebookViewState();
}

class _StudentGradebookViewState extends State<StudentGradebookView> {
  late Future<List<_GradeItem>> _loading;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<List<_GradeItem>> _load() async {
    final classes = await getIt<ClassesRepository>().getMyClasses();
    final assignmentsRepository = getIt<AssignmentsRepository>();
    final examsRepository = getIt<ExamsRepository>();
    final results = await Future.wait<dynamic>([
      Future.wait(
        classes.map(
          (item) => assignmentsRepository.getClassAssignments(item.id),
        ),
      ),
      examsRepository.getMyExamResults(),
      examsRepository.getExams(),
    ]);
    final assignments = results[0] as List<List<dynamic>>;
    final attempts = results[1] as List<dynamic>;
    final exams = results[2] as List<dynamic>;
    final examById = {for (final exam in exams) exam.id as String: exam};
    final classById = {for (final item in classes) item.id: item.name};
    final rows = <_GradeItem>[];
    for (var index = 0; index < classes.length; index++) {
      for (final assignment in assignments[index]) {
        final submission = assignment.mySubmission;
        if (submission?.status != 'GRADED' || submission?.score == null) {
          continue;
        }
        rows.add(
          _GradeItem(
            title: assignment.title,
            className: classes[index].name,
            kind: 'Bài tập',
            score: submission!.score!,
            maxScore: assignment.maxScore,
            feedback: submission.feedback,
            date: submission.gradedAt ?? submission.submittedAt,
          ),
        );
      }
    }
    for (final attempt in attempts) {
      if (attempt.status != 'GRADED' || attempt.score == null) continue;
      final exam = examById[attempt.examId];
      rows.add(
        _GradeItem(
          title: exam?.title ?? 'Bài kiểm tra',
          className: classById[exam?.classId] ?? exam?.className ?? 'Lớp học',
          kind: 'Bài kiểm tra',
          score: attempt.score!,
          maxScore: attempt.maxScore,
          date: attempt.submittedAt ?? attempt.startedAt,
        ),
      );
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  Future<void> _refresh() async {
    setState(() => _loading = _load());
    try {
      await _loading;
    } catch (_) {
      // FutureBuilder displays the error and retry action.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_GradeItem>>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không tải được bảng điểm.'),
              TextButton(onPressed: _refresh, child: const Text('Thử lại')),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      final isMobile =
          AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
          AdaptiveSize.mobile;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: ValueKey(
            isMobile ? 'student-gradebook-mobile' : 'student-gradebook-desktop',
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          children: [
            Text(
              'Bảng điểm của tôi',
              style: TextStyle(
                fontSize: isMobile ? 23 : 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kết quả bài tập và bài kiểm tra đã công bố',
              style: TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: MobileTokens.sectionGap),
            _summary(items),
            const SizedBox(height: MobileTokens.sectionGap),
            Text(
              '${items.length} kết quả',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const MobileSectionCard(
                child: Text('Chưa có bài nào được chấm và công bố.'),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _gradeCard(item),
              ),
          ],
        ),
      );
    },
  );

  Widget _summary(List<_GradeItem> items) {
    final normalized = items.where((item) => item.maxScore > 0).toList();
    final mean = normalized.isEmpty
        ? null
        : normalized
                  .map((item) => item.score / item.maxScore * 10)
                  .reduce((a, b) => a + b) /
              normalized.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trung bình các bài đã chấm',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            mean == null ? 'Chưa có điểm' : '${mean.toStringAsFixed(1)} / 10',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.length} kết quả đã công bố · Chưa phải điểm tổng kết khóa học',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(_GradeItem item) => MobileSectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.className,
                    style: const TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.score.toStringAsFixed(1)}/${item.maxScore.toStringAsFixed(1)}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        MobileStatusPill(label: item.kind, color: AppColors.primary),
        if (item.feedback?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text('Nhận xét: ${item.feedback}'),
        ],
      ],
    ),
  );
}

class _GradeItem {
  const _GradeItem({
    required this.title,
    required this.className,
    required this.kind,
    required this.score,
    required this.maxScore,
    required this.date,
    this.feedback,
  });
  final String title;
  final String className;
  final String kind;
  final double score;
  final double maxScore;
  final String date;
  final String? feedback;
}
