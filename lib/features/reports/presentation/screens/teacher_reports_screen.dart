import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
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
}
