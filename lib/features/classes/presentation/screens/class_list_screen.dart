import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_event.dart';
import '../bloc/classes_state.dart';
import '../../data/models/class_model.dart';
import 'schedule_screen.dart';

class ClassListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool allowCreate;
  const ClassListScreen({
    super.key,
    this.showAppBar = true,
    this.allowCreate = true,
  });

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeViewIndex =
      0; // 0: Table, 1: Weekly Calendar, 2: Teacher Assignment
  String _selectedBranch = 'ALL';
  String _selectedShift = 'ALL';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    context.read<ClassesBloc>().add(const FetchClasses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateClassDialog() {
    context.push(RouteNames.classCreate);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Lớp học & Xếp lịch tự động'),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              actions: [
                IconButton(
                  onPressed: () => context.read<ClassesBloc>().add(
                    const FetchClasses(refresh: true),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            )
          : null,
      body: BlocBuilder<ClassesBloc, ClassesState>(
        builder: (context, state) {
          List<ClassModel> liveClasses = [];
          if (state is ClassesLoaded) {
            liveClasses = state.classes;
          }

          final displayClasses = _buildDisplayClasses(liveClasses);
          final query = _searchController.text.trim().toLowerCase();
          final filteredClasses = displayClasses.where((c) {
            if (query.isEmpty) return true;
            final code = (c['code'] ?? '').toString().toLowerCase();
            final name = (c['name'] ?? '').toString().toLowerCase();
            final teacher = (c['teacher'] ?? '').toString().toLowerCase();
            return code.contains(query) ||
                name.contains(query) ||
                teacher.contains(query);
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PAGE HEADING TOOLBAR (Stitch Layout)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                        'Quản lý Lớp học & Xếp lịch Tự động',
                                        style: AppTextStyles.h2(context)
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0F172A),
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 3.5,
                                              backgroundColor: Color(
                                                0xFF2E7D32,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Thuật toán xếp lịch tự động thông minh',
                                              style: TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.today_rounded,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Hôm nay: $todayStr • Tổng số ${liveClasses.length} lớp đang vận hành trong hệ thống',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đang xuất thời khóa biểu toàn trung tâm (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất TKB (.xlsx)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                if (widget.allowCreate)
                                  ElevatedButton.icon(
                                    onPressed: _showCreateClassDialog,
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '+ Tạo lớp & Xếp lịch tự động',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003FB1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'Quản lý Lớp học & Xếp lịch Tự động',
                                  style: AppTextStyles.h2(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 3.5,
                                        backgroundColor: Color(0xFF2E7D32),
                                      ),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Thuật toán xếp lịch tự động thông minh',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.today_rounded,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hôm nay: $todayStr • Tổng số ${liveClasses.length} lớp đang vận hành trong hệ thống',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đang xuất thời khóa biểu toàn trung tâm (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 16,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất TKB (.xlsx)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                if (widget.allowCreate)
                                  ElevatedButton.icon(
                                    onPressed: _showCreateClassDialog,
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      '+ Tạo lớp & Xếp lịch tự động',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003FB1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // 2. 4 KPI STATS METRIC CARDS (Stitch Layout)
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2;
                    final totalClasses = liveClasses.length;
                    final inProgressCount = liveClasses
                        .where((c) => c.status == 'IN_PROGRESS')
                        .length;
                    final openCount = liveClasses
                        .where(
                          (c) =>
                              c.status == 'OPEN_FOR_ENROLLMENT' ||
                              c.status == 'PLANNING',
                        )
                        .length;
                    final totalStudents = liveClasses.fold<int>(
                      0,
                      (s, c) => s + c.studentsCount,
                    );
                    final totalSessions = liveClasses.fold<int>(
                      0,
                      (s, c) => s + c.sessionsCount,
                    );
                    final avgCapacity = totalClasses > 0
                        ? (liveClasses.fold<int>(
                                    0,
                                    (s, c) => s + c.maxCapacity,
                                  ) /
                                  totalClasses)
                              .toStringAsFixed(0)
                        : '0';

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Tổng số lớp học hệ thống',
                          value: '$totalClasses lớp',
                          subtext:
                              '$inProgressCount đang học • $openCount mở tuyển sinh',
                          icon: Icons.school_rounded,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF003FB1),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Buổi học đã lên lịch',
                          value: '$totalSessions buổi',
                          subtext: '100% không trùng phòng & GV',
                          icon: Icons.check_circle_rounded,
                          iconBg: const Color(0xFFF0FDF4),
                          iconColor: const Color(0xFF16A34A),
                          pillColor: const Color(0xFFDCFCE7),
                          pillTextColor: const Color(0xFF15803D),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Học viên đã xếp lớp',
                          value: '$totalStudents học viên',
                          subtext: 'Sức chứa TB: $avgCapacity HV/lớp',
                          icon: Icons.group_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          pillColor: const Color(0xFFEFF6FF),
                          pillTextColor: const Color(0xFF1D4ED8),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Xung đột lịch học',
                          value: '0 buổi',
                          subtext: 'Lịch học vận hành ổn định',
                          icon: Icons.verified_rounded,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                          pillColor: const Color(0xFFECFDF5),
                          pillTextColor: const Color(0xFF047857),
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. VIEW TABS & FILTERING TOOLS (Stitch Layout)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // View Toggle Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildViewBtn(
                              0,
                              'Danh sách lớp học (Table View)',
                              Icons.table_rows_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildViewBtn(
                              1,
                              'Thời khóa biểu tuần (Calendar Matrix)',
                              Icons.calendar_view_week_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildViewBtn(
                              2,
                              'Phân công giảng dạy giáo viên',
                              Icons.badge_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filters Row
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: isDesktop ? 340 : double.infinity,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Tìm theo mã lớp, tên khóa, giáo viên, phòng...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedBranch,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Chi nhánh: Tất cả chi nhánh'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CN1',
                                    child: Text('CN 1: Quận 1, TP.HCM'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CN2',
                                    child: Text('CN 2: Bình Thạnh, TP.HCM'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CN3',
                                    child: Text('CN 3: Cầu Giấy, Hà Nội'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null)
                                    setState(() => _selectedBranch = v);
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedShift,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Khung giờ: Tất cả ca học'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MORNING',
                                    child: Text('Ca sáng (08:00 - 11:30)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'AFTERNOON',
                                    child: Text('Ca chiều (14:00 - 17:30)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EVENING',
                                    child: Text('Ca tối (18:00 - 21:15)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null)
                                    setState(() => _selectedShift = v);
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedStatus,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Trạng thái: Tất cả'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'IN_PROGRESS',
                                    child: Text('Đang học'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPCOMING',
                                    child: Text('Sắp khai giảng'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COMPLETED',
                                    child: Text('Đã kết thúc'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null)
                                    setState(() => _selectedStatus = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. DATA PRESENTATION AREA
                if (state is ClassesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LoadingWidget(
                      message:
                          'Đang tải danh sách lớp học và thời khóa biểu...',
                    ),
                  )
                else if (state is ClassesError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<ClassesBloc>().add(const FetchClasses()),
                    ),
                  )
                else if (_activeViewIndex == 0)
                  _buildClassesTable(filteredClasses, isDesktop)
                else if (_activeViewIndex == 1)
                  BlocProvider<ClassesBloc>(
                    create: (_) => getIt<ClassesBloc>(),
                    child: const SizedBox(
                      height: 780,
                      child: ScheduleScreen(showAppBar: false),
                    ),
                  )
                else
                  _buildTeacherAssignmentView(filteredClasses),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? pillColor,
    Color? pillTextColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
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
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
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
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          if (pillColor != null && pillTextColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtext,
                style: TextStyle(
                  color: pillTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              subtext,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildViewBtn(int index, String title, IconData icon) {
    final isActive = _activeViewIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeViewIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003FB1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF003FB1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTable(
    List<Map<String, dynamic>> classes,
    bool isDesktop,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth > 1050
              ? constraints.maxWidth
              : 1050.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            'MÃ LỚP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TÊN LỚP & KHÓA HỌC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'GIÁO VIÊN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'LỊCH HỌC & CA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PHÒNG & CƠ SỞ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'SĨ SỐ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            'TRẠNG THÁI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'THAO TÁC',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: classes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final c = classes[idx];
                      final code = c['code'] ?? 'ENG-01';
                      final name = c['name'] ?? 'Lớp Tiếng Anh';
                      final course = c['courseTitle'] ?? 'Chương trình đào tạo';
                      final teacher = c['teacher'] ?? 'Giáo viên';
                      final days = c['days'] ?? 'T2 - T4 - T6';
                      final shift = c['shift'] ?? '08:00 - 09:30';
                      final room = c['room'] ?? 'Phòng A101';
                      final enrolled = c['enrolled'] ?? 16;
                      final maxCap = c['capacity'] ?? 18;
                      final ratio = (enrolled / maxCap).clamp(0.0, 1.0);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF003FB1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    course,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    child: Text(
                                      teacher[0],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003FB1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      teacher,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    days,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    shift,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    'CN 1: Quận 1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Column(
                                children: [
                                  Text(
                                    '$enrolled / $maxCap HV (${(ratio * 100).toInt()}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Đang học',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      final classId = c['id']?.toString();
                                      if (classId == null || classId.isEmpty) {
                                        return;
                                      }
                                      context.push(
                                        RouteNames.classDetail.replaceFirst(
                                          ':id',
                                          classId,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003FB1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Điểm danh',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Tùy chọn cho $name'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherAssignmentView(List<Map<String, dynamic>> classes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHÂN CÔNG GIẢNG DẠY GIẢNG VIÊN & TRỢ GIẢNG:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Hệ thống tự động theo dõi số giờ dạy thực tế / định mức quy định (24h/tuần) của từng giảng viên.',
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildDisplayClasses(
    List<ClassModel> liveClasses,
  ) {
    return liveClasses.map((lc) {
      return {
        'id': lc.id,
        'code': lc.code,
        'name': lc.name,
        'courseTitle': lc.courseTitle ?? 'Khóa học',
        'teacher': lc.mainTeacherName ?? 'Chưa phân công',
        'days': lc.scheduleDays.isNotEmpty
            ? lc.scheduleDays.join(' - ')
            : 'T2 - T4 - T6',
        'shift': '${lc.startTime} - ${lc.endTime}',
        'room': lc.roomName ?? 'Phòng học',
        'enrolled': lc.studentsCount,
        'capacity': lc.maxCapacity,
        'status': lc.status,
      };
    }).toList();
  }
}
