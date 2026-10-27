import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/reports_bloc.dart';
import '../../data/models/report_model.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final bool showAppBar;
  const TeacherDashboardScreen({super.key, this.showAppBar = true});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late Future<List<ClassSessionModel>> _schedule;

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(FetchTeacherWorkloadEvent());
    final today = DateTime.now();
    _schedule = getIt<ClassesRepository>().getMySchedule(
      fromDate: DateFormat('yyyy-MM-dd').format(today),
      toDate: DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 7))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Tổng Quan Giảng Dạy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                  onPressed: () =>
                      context.read<ReportsBloc>().add(FetchTeacherWorkloadEvent()),
                ),
              ],
            )
          : null,
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          TeacherWorkloadModel? currentTeacher;
          if (state is TeacherWorkloadLoadedState) {
            final teachers = state.data;
            if (teachers.isNotEmpty) currentTeacher = teachers.first;
          }

          final authState = context.read<AuthBloc>().state;
          String teacherName = 'Thầy Nguyễn Văn Dũng';
          if (authState is AuthenticatedState) {
            teacherName = authState.user.fullName;
          } else if (currentTeacher != null &&
              currentTeacher.fullName.isNotEmpty) {
            teacherName = currentTeacher.fullName;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Greeting Banner / Page Header
                    _buildGreetingBanner(teacherName, isDesktop),
                    const SizedBox(height: 20),

                    // 2. Four Quick Stat Cards
                    _buildStatCardsGrid(currentTeacher, isDesktop),
                    const SizedBox(height: 24),

                    // 3. Main Workspace Grid (Left 65% / Right 35%)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                _buildTodayScheduleWidget(context),
                                const SizedBox(height: 24),
                                _buildPendingGradingWidget(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildAcademicAlertsWidget(context),
                                const SizedBox(height: 24),
                                _buildCurriculumTrackerWidget(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTodayScheduleWidget(context),
                          const SizedBox(height: 20),
                          _buildPendingGradingWidget(context),
                          const SizedBox(height: 20),
                          _buildAcademicAlertsWidget(context),
                          const SizedBox(height: 20),
                          _buildCurriculumTrackerWidget(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 1. GREETING BANNER ---
  Widget _buildGreetingBanner(String teacherName, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Chào buổi sáng, $teacherName! 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          children: [
                            TextSpan(text: 'Hôm nay '),
                            TextSpan(
                              text: '24/10/2026',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' • Bạn đang phụ trách '),
                            TextSpan(
                              text: '2 lớp học',
                              style: TextStyle(
                                color: Color(0xFF003FB1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' (1 lớp đang học, 1 lớp tuyển sinh) và '),
                            TextSpan(
                              text: '1 bài tập cần chấm điểm',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.schedule),
              icon: const Icon(Icons.date_range_outlined, size: 16),
              label: const Text('Xem TKB tuần'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.schedule),
              icon: const Icon(Icons.how_to_reg, size: 16),
              label: const Text('Điểm danh ca hiện tại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003FB1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. FOUR QUICK STAT CARDS ---
  Widget _buildStatCardsGrid(
      TeacherWorkloadModel? teacher, bool isDesktop) {
    final activeClasses = teacher?.activeClassesCount ?? 2;
    final teachingHours = teacher?.totalTeachingHours ?? 36;

    final cards = [
      _buildKpiCard(
        title: 'Lớp học đang phụ trách',
        value: '$activeClasses lớp',
        subtitle: 'Tổng 1 học viên active',
        badgeText: '100% đúng tiến độ',
        badgeColor: const Color(0xFF10B981),
        icon: Icons.groups_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF003FB1),
      ),
      _buildProgressKpiCard(
        title: 'Giờ dạy tích lũy tháng 10',
        value: '$teachingHours / 60 giờ',
        progress: (teachingHours / 60).clamp(0.0, 1.0),
        progressLabel: 'Tiến độ hợp đồng: ${(teachingHours / 60 * 100).toStringAsFixed(1)}%',
        icon: Icons.schedule_rounded,
        iconBgColor: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
      ),
      _buildKpiCard(
        title: 'Bài tập chờ chấm',
        value: '1 bài nộp',
        subtitle: '1 bài Writing (Em Lê Minh Khang)',
        badgeText: 'Cần duyệt ngay',
        badgeColor: const Color(0xFFF59E0B),
        icon: Icons.edit_note_rounded,
        iconBgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      ),
      _buildKpiCard(
        title: 'Tỷ lệ chuyên cần trung bình',
        value: '100%',
        subtitle: 'Tính trên $activeClasses lớp hệ thống',
        badgeText: 'Sĩ số đầy đủ',
        badgeColor: const Color(0xFF10B981),
        icon: Icons.verified_user_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        } else if (constraints.maxWidth > 600) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((card) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: card,
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressKpiCard({
    required String title,
    required String value,
    required double progress,
    required String progressLabel,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressLabel,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. WIDGET 1: TODAY SCHEDULE ---
  Widget _buildTodayScheduleWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF003FB1),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch dạy các lớp phụ trách',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Các buổi dạy trong 7 ngày tới',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push(RouteNames.schedule),
                  child: const Text(
                    'Toàn bộ lịch tuần →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003FB1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<List<ClassSessionModel>>(
              future: _schedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return const Text('Không tải được lịch dạy.');
                final now = DateTime.now();
                final sessions = (snapshot.data ?? []).where((session) {
                  final day = session.date;
                  return day != null &&
                      !DateTime(day.year, day.month, day.day).isBefore(DateTime(now.year, now.month, now.day)) &&
                      session.status != 'CANCELLED';
                }).toList()
                  ..sort((a, b) {
                    final date = a.date!.compareTo(b.date!);
                    return date != 0 ? date : a.startTime.compareTo(b.startTime);
                  });
                if (sessions.isEmpty) return const Text('Không có lịch dạy trong 7 ngày tới.');
                return Column(
                  children: sessions.map((session) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(session.className ?? session.classCode ?? 'Lớp học'),
                      subtitle: Text('${DateFormat('dd/MM').format(session.date!)} • ${session.startTime}–${session.endTime} • ${session.roomName ?? session.roomCode ?? 'Chưa xếp phòng'}'),
                      trailing: IconButton(
                        tooltip: 'Điểm danh',
                        onPressed: () => context.push(RouteNames.attendanceMark.replaceFirst(':id', session.id)),
                        icon: const Icon(Icons.how_to_reg),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. WIDGET 2: PENDING GRADING ---
  Widget _buildPendingGradingWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFFD97706),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bài tập học viên mới nộp',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(width: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                child: Text(
                                  '1 bài chờ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Học viên nộp bài Writing và Speaking cần phản hồi trong vòng 48h',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Xem tất cả (1) →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003FB1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              _buildSubmissionItem(
                avatarText: 'MK',
                avatarBg: const Color(0xFF2563EB),
                studentName: 'Em Lê Minh Khang',
                classTag: 'IELTS-F-2026-01',
                submittedTime: 'Hôm nay, 08:45',
                taskTitle: 'Writing Task 2: Opinion Essay',
                fileType: 'PDF',
                fileName: 'MinhKhang_IELTS_Task2.pdf (1.2 MB)',
                fileColor: const Color(0xFFEF4444),
                actionLabel: 'Chấm bài ngay',
                actionColor: const Color(0xFF003FB1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionItem({
    required String avatarText,
    required Color avatarBg,
    required String studentName,
    required String classTag,
    required String submittedTime,
    required String taskTitle,
    required String fileType,
    required String fileName,
    required Color fileColor,
    required String actionLabel,
    required Color actionColor,
    bool isOutline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarBg,
            child: Text(
              avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        classTag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $submittedTime',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: fileColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fileType == 'PDF'
                                ? Icons.picture_as_pdf
                                : fileType == 'AUDIO'
                                    ? Icons.graphic_eq
                                    : Icons.description,
                            size: 11,
                            color: fileColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: fileColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isOutline)
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
              child: Text(actionLabel),
            )
          else
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  // --- 5. WIDGET 3: ACADEMIC ALERTS (Right column) ---
  Widget _buildAcademicAlertsWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFE11D48),
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Nhắc nhở học vụ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '3 tin mới',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Alert 1: Absent warning (Red)
                _buildAlertItem(
                  borderColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  title: 'Cảnh báo vắng học liên tiếp',
                  titleColor: const Color(0xFF991B1B),
                  icon: Icons.warning_amber_rounded,
                  description:
                      'Học viên Nguyễn Tuấn Kiệt (Lớp IELTS Fighter) đã vắng 2 buổi liên tiếp không phép.',
                  actionText: 'Liên hệ học vụ',
                ),
                const SizedBox(height: 10),
                // Alert 2: Midterm grade deadline (Blue)
                _buildAlertItem(
                  borderColor: const Color(0xFF003FB1),
                  bgColor: const Color(0xFFEFF6FF),
                  title: 'Hạn nộp điểm giữa kỳ',
                  titleColor: const Color(0xFF1E3A8A),
                  icon: Icons.event_note,
                  description:
                      'Hạn nộp bảng điểm giữa kỳ lớp TOEIC 650+ Intensive là ngày 28/10/2026.',
                  actionText: 'Nhập bảng điểm ngay',
                ),
                const SizedBox(height: 10),
                // Alert 3: Lab room maintenance (Gray)
                _buildAlertItem(
                  borderColor: const Color(0xFF94A3B8),
                  bgColor: const Color(0xFFF8FAFC),
                  title: 'Cơ sở vật chất hoàn tất',
                  titleColor: const Color(0xFF334155),
                  icon: Icons.build_circle_outlined,
                  description:
                      'Phòng Lab C02 đã được bảo trì dàn máy tính & tai nghe hoàn tất cho ca chiều.',
                  actionText: '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required Color borderColor,
    required Color bgColor,
    required String title,
    required Color titleColor,
    required IconData icon,
    required String description,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: borderColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          if (actionText.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {},
              child: Text(
                '$actionText →',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 6. WIDGET 4: CURRICULUM TRACKER (Right column) ---
  Widget _buildCurriculumTrackerWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tiến độ giáo trình',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF003FB1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCurriculumItem(
                  title: 'Lớp IELTS Foundation K01',
                  tag: 'FOUNDATION',
                  percent: 0.25,
                  sub1: 'Chương trình Luyện thi IELTS Chuyên sâu',
                  sub2: '24 buổi (Đang học)',
                  barColor: const Color(0xFF003FB1),
                ),
                const SizedBox(height: 14),
                _buildCurriculumItem(
                  title: 'Lớp Giao Tiếp A1 K01',
                  tag: 'COMM-A1',
                  percent: 0.0,
                  sub1: 'Tiếng Anh Giao Tiếp Phản Xạ Quốc Tế',
                  sub2: '20 buổi (Đang tuyển sinh)',
                  barColor: const Color(0xFF059669),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumItem({
    required String title,
    required String tag,
    required double percent,
    required String sub1,
    required String sub2,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003FB1),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sub1,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              sub2,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
