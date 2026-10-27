import 'package:flutter/material.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../data/models/report_model.dart';
import '../../domain/repositories/reports_repository.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  late Future<List<ClassModel>> _classes;
  late Future<(AttendanceReportModel, AcademicReportModel)> _reports;
  String? _classId;

  @override
  void initState() {
    super.initState();
    _classes = getIt<ClassesRepository>().getMyClasses();
    _loadReports();
  }

  void _loadReports() {
    final repository = getIt<ReportsRepository>();
    _reports =
        Future.wait<dynamic>([
          repository.getAttendanceReport(classId: _classId),
          repository.getAcademicReport(classId: _classId),
        ]).then(
          (values) => (
            values[0] as AttendanceReportModel,
            values[1] as AcademicReportModel,
          ),
        );
  }

  void _refresh() => setState(() {
    _classes = getIt<ClassesRepository>().getMyClasses();
    _loadReports();
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Báo cáo giảng dạy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ClassModel>>(
          future: _classes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Không tải được danh sách lớp: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final classes = snapshot.data!;
            if (classes.isEmpty) {
              return const Text('Bạn chưa được phân công lớp học.');
            }
            return DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: classes.any((item) => item.id == _classId)
                  ? _classId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Lớp học',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tất cả lớp của tôi'),
                ),
                ...classes.map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                ),
              ],
              onChanged: (value) => setState(() {
                _classId = value == null || value.isEmpty ? null : value;
                _loadReports();
              }),
            );
          },
        ),
        const SizedBox(height: 20),
        FutureBuilder<(AttendanceReportModel, AcademicReportModel)>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              final message =
                  error is ApiException && (error.statusCode ?? 0) >= 500
                  ? 'Máy chủ đang gặp lỗi khi tổng hợp báo cáo. Vui lòng thử lại.'
                  : error is ApiException
                  ? error.message
                  : 'Không tải được dữ liệu báo cáo. Vui lòng thử lại.';
              return Column(
                children: [
                  Text(message, textAlign: TextAlign.center),
                  TextButton(onPressed: _refresh, child: const Text('Thử lại')),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final (attendance, academic) = snapshot.data!;
            if (AdaptiveBreakpoints.fromWidth(
                  MediaQuery.sizeOf(context).width,
                ) ==
                AdaptiveSize.mobile) {
              return _buildMobileReports(attendance, academic);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric(
                      'Tỷ lệ chuyên cần',
                      '${attendance.attendanceRate.toStringAsFixed(1)}%',
                    ),
                    _metric('Lượt điểm danh', '${attendance.totalRecords}'),
                    _metric('Vắng', '${attendance.absentCount}'),
                    _metric('Lượt thi', '${academic.totalAttempts}'),
                    _metric(
                      'Điểm trung bình',
                      academic.averageScore.toStringAsFixed(1),
                    ),
                    _metric(
                      'Tỷ lệ đạt',
                      '${academic.passRate.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Chuyên cần theo lớp',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (attendance.byClass.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Chưa có dữ liệu điểm danh.'),
                  ),
                ...attendance.byClass.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.present}/${item.total} lượt có mặt',
                      ),
                      trailing: Text(
                        '${item.attendanceRate.toStringAsFixed(1)}%',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kết quả học tập',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (academic.topStudents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Chưa có bài kiểm tra được chấm.'),
                  ),
                ...academic.topStudents.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.studentName),
                      subtitle: Text('${item.studentCode} • ${item.examTitle}'),
                      trailing: Text(item.score.toStringAsFixed(1)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metric(String label, String value) => Card(
    child: SizedBox(
      width: 175,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );

  Widget _buildMobileReports(
    AttendanceReportModel attendance,
    AcademicReportModel academic,
  ) => Column(
    key: const ValueKey('teacher-reports-mobile'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(MobileTokens.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chuyên cần', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              '${attendance.attendanceRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${attendance.presentCount}/${attendance.totalRecords} lượt có mặt',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _mobileMetric(
              'Lượt thi',
              '${academic.totalAttempts}',
              Icons.quiz_outlined,
            ),
            _mobileMetric(
              'Điểm trung bình',
              academic.averageScore.toStringAsFixed(1),
              Icons.grade_outlined,
            ),
            _mobileMetric(
              'Tỷ lệ đạt',
              '${academic.passRate.toStringAsFixed(1)}%',
              Icons.trending_up_outlined,
            ),
            _mobileMetric(
              'Lượt vắng',
              '${attendance.absentCount}',
              Icons.person_off_outlined,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Chuyên cần theo lớp',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      if (attendance.byClass.isEmpty)
        const MobileSectionCard(child: Text('Chưa có dữ liệu điểm danh.')),
      for (final item in attendance.byClass)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.present}/${item.total} lượt có mặt · ${item.attendanceRate.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 20),
      Text('Kết quả học tập', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (academic.topStudents.isEmpty)
        const MobileSectionCard(child: Text('Chưa có bài kiểm tra được chấm.')),
      for (final item in academic.topStudents)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MobileSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${item.studentCode} · ${item.examTitle}',
                        style: const TextStyle(color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _mobileMetric(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: SizedBox(
      width: 145,
      child: MobileSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
