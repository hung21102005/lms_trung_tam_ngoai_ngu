import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
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
          if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
              AdaptiveSize.mobile) {
            return _buildMobileDashboard(
              name,
              data,
              sessions,
              submissions,
              classes,
              alerts,
            );
          }
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
                      onPressed: () =>
                          context.push(RouteNames.teacherAssignments),
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

  Widget _buildMobileDashboard(
    String name,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> submissions,
    List<Map<String, dynamic>> classes,
    List<Map<String, dynamic>> alerts,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_refresh);
        await _dashboard;
      },
      child: ListView(
        key: const ValueKey('teacher-dashboard-mobile'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Text(
            'Xin chào, $name',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: const TextStyle(color: AppColors.neutral600),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          Container(
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
                  'Việc cần làm hôm nay',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data['sessionsToday'] ?? 0} buổi dạy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['pendingAssignments'] ?? 0} bài tập chờ chấm',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 106,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _mobileMetric(
                  'Lớp phụ trách',
                  '${data['activeClasses'] ?? 0}',
                  Icons.groups_outlined,
                ),
                _mobileMetric(
                  'Học viên',
                  '${data['totalStudents'] ?? 0}',
                  Icons.school_outlined,
                ),
                _mobileMetric(
                  'Cần theo dõi',
                  '${data['studentsNeedingAttention'] ?? 0}',
                  Icons.person_search_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Lịch dạy'),
                onPressed: () => context.push(RouteNames.schedule),
              ),
              ActionChip(
                label: const Text('Chấm bài'),
                onPressed: () => context.push(RouteNames.teacherAssignments),
              ),
              ActionChip(
                label: const Text('Bài kiểm tra'),
                onPressed: () => context.push(RouteNames.exams),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Lịch dạy sắp tới',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const MobileSectionCard(child: Text('Không có buổi dạy sắp tới.')),
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MobileSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(session['class'] as Map?)?['name'] ?? 'Lớp học'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('${session['title'] ?? ''}'),
                    const SizedBox(height: 5),
                    Text(
                      '${session['date'] ?? ''} · ${session['startTime'] ?? ''}–${session['endTime'] ?? ''}',
                      style: const TextStyle(color: AppColors.neutral600),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(
                        RouteNames.attendanceMark.replaceFirst(
                          ':id',
                          '${session['id']}',
                        ),
                      ),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Điểm danh'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Bài nộp cần chấm',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (submissions.isEmpty)
            const MobileSectionCard(child: Text('Không có bài nộp chờ chấm.')),
          for (final submission in submissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MobileSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(submission['student'] as Map?)?['fullName'] ?? 'Học viên'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${(submission['assignment'] as Map?)?['title'] ?? 'Bài tập'}',
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(
                        RouteNames.reviewSubmission
                            .replaceFirst(
                              ':id',
                              '${submission['assignmentId']}',
                            )
                            .replaceFirst(
                              ':studentId',
                              '${(submission['student'] as Map?)?['id']}',
                            ),
                      ),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Xem và chấm bài'),
                    ),
                  ],
                ),
              ),
            ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Học viên cần theo dõi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final student in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MobileSectionCard(
                  child: Text(
                    '${student['fullName'] ?? 'Học viên'} · ${student['absencesLast30Days'] ?? 0} buổi vắng',
                  ),
                ),
              ),
          ],
          if (classes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Lớp học của tôi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final item in classes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MobileSectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['name'] ?? 'Lớp học'}'),
                    subtitle: Text('${item['studentsCount'] ?? 0} học viên'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      RouteNames.classDetail.replaceFirst(
                        ':id',
                        '${item['id']}',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _mobileMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 150,
        child: MobileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
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
