import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class TeacherDashboardLiveScreen extends StatefulWidget {
  const TeacherDashboardLiveScreen({
    super.key,
    this.showAppBar = true,
    this.loadDashboard,
  });

  final bool showAppBar;
  final Future<dynamic> Function()? loadDashboard;

  @override
  State<TeacherDashboardLiveScreen> createState() =>
      _TeacherDashboardLiveScreenState();
}

class _TeacherDashboardLiveScreenState
    extends State<TeacherDashboardLiveScreen> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => _dashboard = _load();

  Future<Map<String, dynamic>> _load() async {
    final response =
        await (widget.loadDashboard?.call() ??
            getIt<ApiClient>().get('/reports/teacher/dashboard'));
    final data = response is Map ? response['data'] ?? response : response;
    if (data is! Map) {
      throw const FormatException('Dữ liệu dashboard không hợp lệ');
    }
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> data, String key) =>
      (data[key] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final name = auth is AuthenticatedState ? auth.user.fullName : 'Giảng viên';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Tổng quan giảng dạy'),
              actions: [
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: () => setState(_refresh),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tải được dữ liệu giảng dạy.'),
                  TextButton(
                    onPressed: () => setState(_refresh),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          final sessions = _rows(data, 'sessions');
          final submissions = _rows(data, 'pendingSubmissions');
          final classes = _rows(data, 'classes');
          final alerts = _rows(data, 'attendanceAlerts');
          return RefreshIndicator(
            onRefresh: () async {
              setState(_refresh);
              await _dashboard;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Xin chào, $name',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 1000
                        ? (width - 36) / 4
                        : width >= 560
                        ? (width - 12) / 2
                        : width;
                    final metrics = <(String, String, IconData)>[
                      (
                        'Lớp đang phụ trách',
                        '${data['activeClasses'] ?? 0}',
                        Icons.groups_outlined,
                      ),
                      (
                        'Học viên',
                        '${data['totalStudents'] ?? 0}',
                        Icons.school_outlined,
                      ),
                      (
                        'Buổi học tuần này',
                        '${data['sessionsThisWeek'] ?? 0}',
                        Icons.calendar_month_outlined,
                      ),
                      (
                        'Buổi học hôm nay',
                        '${data['sessionsToday'] ?? 0}',
                        Icons.today_outlined,
                      ),
                      (
                        'Bài nộp chờ chấm',
                        '${data['pendingAssignments'] ?? 0}',
                        Icons.assignment_outlined,
                      ),
                      (
                        'Bài kiểm tra chờ chấm',
                        '${data['pendingExams'] ?? 0}',
                        Icons.quiz_outlined,
                      ),
                      (
                        'Học viên cần theo dõi',
                        '${data['studentsNeedingAttention'] ?? 0}',
                        Icons.person_search_outlined,
                      ),
                    ];
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: metrics
                          .map(
                            (metric) => SizedBox(
                              width: cardWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        metric.$3,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        metric.$2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                      Text(metric.$1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Lịch dạy'),
                      onPressed: () => context.push(RouteNames.schedule),
                    ),
                    ActionChip(
                      label: const Text('Bài tập'),
                      onPressed: () => context.push(RouteNames.teacherAssignments),
                    ),
                    ActionChip(
                      label: const Text('Kiểm tra'),
                      onPressed: () => context.push(RouteNames.exams),
                    ),
                    ActionChip(
                      label: Text(
                        'Thông báo (${data['unreadNotifications'] ?? 0})',
                      ),
                      onPressed: () => context.push(RouteNames.notifications),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _section(
                  context,
                  'Lịch dạy 7 ngày tới',
                  sessions.isEmpty
                      ? [
                          const ListTile(
                            title: Text('Không có buổi dạy sắp tới'),
                          ),
                        ]
                      : sessions.map((session) {
                          final classInfo = session['class'] as Map? ?? {};
                          final room = session['room'] as Map? ?? {};
                          final date = DateTime.tryParse('${session['date']}');
                          return ListTile(
                            title: Text(
                              '${classInfo['name'] ?? 'Lớp học'} • ${session['title'] ?? ''}',
                            ),
                            subtitle: Text(
                              '${date == null ? '' : DateFormat('dd/MM').format(date)}  ${session['startTime'] ?? ''}–${session['endTime'] ?? ''}  ${room['name'] ?? ''}',
                            ),
                            trailing: TextButton(
                              onPressed: () => context.push(
                                RouteNames.attendanceMark.replaceFirst(
                                  ':id',
                                  '${session['id']}',
                                ),
                              ),
                              child: const Text('Điểm danh'),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Bài nộp cần chấm',
                  submissions.isEmpty
                      ? [
                          const ListTile(
                            title: Text('Không có bài nộp chờ chấm'),
                          ),
                        ]
                      : submissions.map((submission) {
                          final student = submission['student'] as Map? ?? {};
                          final assignment =
                              submission['assignment'] as Map? ?? {};
                          return ListTile(
                            title: Text(
                              '${student['fullName'] ?? 'Học viên'} • ${assignment['title'] ?? 'Bài tập'}',
                            ),
                            subtitle: Text('${student['userCode'] ?? ''}'),
                            trailing: TextButton(
                              onPressed: () => context.push(
                                RouteNames.reviewSubmission
                                    .replaceFirst(
                                      ':id',
                                      '${submission['assignmentId']}',
                                    )
                                    .replaceFirst(
                                      ':studentId',
                                      '${student['id']}',
                                    ),
                              ),
                              child: const Text('Chấm bài'),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Học viên vắng từ 3 buổi trong 30 ngày',
                  alerts.isEmpty
                      ? [
                          const ListTile(
                            title: Text(
                              'Chưa có học viên cần theo dõi theo tiêu chí chuyên cần.',
                            ),
                          ),
                        ]
                      : alerts
                            .map(
                              (student) => ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(
                                  '${student['fullName'] ?? 'Học viên'} (${student['userCode'] ?? ''})',
                                ),
                                subtitle: Text(
                                  '${student['absencesLast30Days'] ?? 0} buổi vắng không phép',
                                ),
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 16),
                _section(
                  context,
                  'Lớp học của tôi',
                  classes.isEmpty
                      ? [
                          const ListTile(
                            title: Text('Chưa được phân công lớp học'),
                          ),
                        ]
                      : classes
                            .map(
                              (item) => ListTile(
                                title: Text(
                                  '${item['name'] ?? ''} (${item['code'] ?? ''})',
                                ),
                                subtitle: Text(
                                  '${item['studentsCount'] ?? 0} học viên • ${item['status'] ?? ''}',
                                ),
                                onTap: () => context.push(
                                  RouteNames.classDetail.replaceFirst(
                                    ':id',
                                    '${item['id']}',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      );
}
