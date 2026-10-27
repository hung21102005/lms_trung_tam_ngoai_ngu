import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../reports/presentation/screens/teacher_dashboard_live_screen.dart';
import '../../../reports/presentation/screens/teacher_reports_screen.dart';
import '../../../classes/presentation/screens/schedule_screen.dart';
import '../../../classes/presentation/screens/teacher_my_classes_screen.dart';
import '../views/teacher_class_workflow_view.dart';

import 'package:intl/date_symbol_data_local.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _globalSearchController = TextEditingController();
  String _classSearch = '';

  final List<Map<String, dynamic>> _navItems = [
    {
      'title': 'Tổng quan giảng dạy',
      'icon': Icons.dashboard_rounded,
      'badge': null,
    },
    {
      'title': 'Lịch dạy & TKB',
      'icon': Icons.calendar_month_rounded,
      'badge': null,
    },
    {'title': 'Lớp học của tôi', 'icon': Icons.groups_rounded, 'badge': null},
    {'title': 'Điểm danh', 'icon': Icons.fact_check_rounded, 'badge': null},
    {
      'title': 'Bài tập & Chấm bài',
      'icon': Icons.assignment_rounded,
      'badge': null,
    },
    {'title': 'Kết quả bài tập', 'icon': Icons.grade_rounded, 'badge': null},
    {
      'title': 'Báo cáo giảng dạy',
      'icon': Icons.bar_chart_rounded,
      'badge': null,
    },
    {
      'title': 'Bài kiểm tra',
      'icon': Icons.quiz_outlined,
      'route': RouteNames.exams,
    },
    {
      'title': 'Thông báo',
      'icon': Icons.notifications_outlined,
      'route': RouteNames.notifications,
    },
    {
      'title': 'Hồ sơ cá nhân',
      'icon': Icons.person_outline,
      'route': RouteNames.profile,
    },
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  Widget _buildActiveBody() {
    Widget child;
    switch (_selectedIndex) {
      case 0:
        child = const TeacherDashboardLiveScreen(showAppBar: false);
        break;
      case 1:
        child = const ScheduleScreen(showAppBar: false);
        break;
      case 2:
        child = TeacherMyClassesScreen(initialSearch: _classSearch);
        break;
      case 3:
        child = const TeacherClassWorkflowView(
          mode: TeacherWorkflowMode.attendance,
        );
        break;
      case 4:
        child = const TeacherClassWorkflowView(
          mode: TeacherWorkflowMode.assignments,
        );
        break;
      case 5:
        child = const TeacherClassWorkflowView(
          mode: TeacherWorkflowMode.results,
        );
        break;
      case 6:
        child = const TeacherReportsScreen();
        break;
      default:
        child = const TeacherDashboardLiveScreen(showAppBar: false);
    }
    return KeyedSubtree(key: ValueKey<int>(_selectedIndex), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.desktop;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        final user = state is AuthenticatedState ? state.user : null;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Row(
              children: [
                _buildDesktopSidebar(context, user),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context, user),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          child: SizedBox.expand(child: _buildActiveBody()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout (Pixel 9 emulator & mobile devices)
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _navItems[_selectedIndex]['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              const NotificationBellIcon(),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push(RouteNames.profile),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: _buildMobileDrawer(context, user),
          body: SizedBox.expand(child: _buildActiveBody()),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex == 4
                ? 3
                : (_selectedIndex < 3 ? _selectedIndex : 0),
            onDestinationSelected: (idx) {
              setState(() {
                if (idx == 3) {
                  _selectedIndex = 4; // Chấm bài -> TeacherGradingView
                } else {
                  _selectedIndex = idx;
                }
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Lịch dạy',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Lớp học',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'Chấm bài',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, dynamic user) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        children: [
          // Brand Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
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
                            'EduLMS',
                            style: AppTextStyles.h4(context)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'v2.4',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Cổng Giảng Viên',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          // Action Button: + Giao bài tập mới
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4; // Chấm bài & Giao bài
                  });
                },
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  '+ Giao bài tập mới',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () {
                      final route = item['route'] as String?;
                      if (route != null) {
                        context.push(route);
                        return;
                      }
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : AppColors.neutral600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.neutral800,
                              ),
                            ),
                          ),
                          if (item['badge'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          // User Card & Logout
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    user != null && (user.fullName as String).isNotEmpty
                        ? (user.fullName as String)[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Giảng viên',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.userCode ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  tooltip: 'Đăng xuất',
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequestedEvent());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, dynamic user) {
    final isCompactDesktop = MediaQuery.of(context).size.width <= 1100;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'EduLMS - Cổng Thông Tin Giảng Viên',
                    style: AppTextStyles.h4(context)
                        .copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Global Search
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 360),
              child: TextField(
                controller: _globalSearchController,
                onSubmitted: (value) => setState(() {
                  _classSearch = value.trim();
                  _selectedIndex = 2;
                }),
                decoration: InputDecoration(
                  hintText: isCompactDesktop
                      ? 'Tìm kiếm...'
                      : 'Tìm lớp, lịch dạy, bài tập...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.neutral500,
                  ),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Current Branch / Term
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      user?.branchName ?? 'Chưa gán chi nhánh',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const NotificationBellIcon(),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => context.push(RouteNames.profile),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, dynamic user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              user?.fullName ?? 'Giảng viên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              '${user?.userCode ?? "GV"} • ${user?.branchName ?? "Hệ thống"}',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user != null && (user.fullName as String).isNotEmpty
                    ? (user.fullName as String)[0].toUpperCase()
                    : 'G',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.neutral700,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutral900,
                    ),
                  ),
                  trailing: item['badge'] != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['badge'] as String,
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                  selected: isSelected,
                  onTap: () {
                    final route = item['route'] as String?;
                    if (route != null) {
                      Navigator.pop(context);
                      context.push(route);
                      return;
                    }
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequestedEvent());
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
