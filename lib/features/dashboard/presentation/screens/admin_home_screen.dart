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
import '../../../reports/presentation/bloc/reports_bloc.dart';
import '../../../reports/presentation/screens/admin_dashboard_screen.dart';
import '../../../reports/presentation/screens/reports_overview_screen.dart';
import '../../../courses/presentation/bloc/courses_bloc.dart';
import '../../../courses/presentation/bloc/courses_event.dart';
import '../../../courses/presentation/screens/course_list_screen.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../classes/presentation/screens/class_list_screen.dart';
import '../views/users_management_view.dart';
import '../views/branches_rooms_view.dart';
import '../views/admissions_crm_view.dart';
import '../views/system_settings_view.dart';
import '../views/teacher_attendance_view.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _globalSearchController = TextEditingController();

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Tổng quan', 'icon': Icons.dashboard_rounded, 'badge': null},
    {'title': 'Quản lý người dùng', 'icon': Icons.group_rounded, 'badge': null},
    {
      'title': 'Quản lý chi nhánh & Phòng',
      'icon': Icons.apartment_rounded,
      'badge': null,
    },
    {
      'title': 'Tuyển sinh & Leads',
      'icon': Icons.person_add_rounded,
      'badge': null,
    },
    {'title': 'Khóa học & Cấp độ', 'icon': Icons.school_rounded, 'badge': null},
    {
      'title': 'Lớp học & Xếp lịch',
      'icon': Icons.calendar_month_rounded,
      'badge': null,
    },
    {
      'title': 'Điểm danh & Chuyên cần',
      'icon': Icons.how_to_reg_rounded,
      'badge': null,
    },
    {
      'title': 'Báo cáo & Tài chính',
      'icon': Icons.bar_chart_rounded,
      'badge': null,
    },
    {
      'title': 'Cài đặt hệ thống',
      'icon': Icons.settings_rounded,
      'badge': null,
    },
  ];

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  void _selectNavTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (!mounted) return;
    switch (index) {
      case 0:
      case 7:
        context.read<ReportsBloc?>()?.add(
          const FetchDashboardOverviewEvent(forceRefresh: true),
        );
        break;
      case 4:
        context.read<CoursesBloc?>()?.add(const FetchCourses(refresh: true));
        break;
      case 5:
        context.read<ClassesBloc?>()?.add(const FetchClasses(refresh: true));
        break;
    }
  }

  Future<void> _openCreateClassFromShell() async {
    final result = await context.push(RouteNames.classCreate);
    if (!mounted) return;
    context.read<ClassesBloc?>()?.add(const FetchClasses(refresh: true));
    context.read<ReportsBloc?>()?.add(
      const FetchDashboardOverviewEvent(forceRefresh: true),
    );
    if (result != null) {
      setState(() {
        _selectedIndex = 5;
      });
    }
  }

  Widget _buildActiveBody() {
    Widget child;
    switch (_selectedIndex) {
      case 0:
        child = const AdminDashboardScreen(showAppBar: false);
        break;
      case 1:
        child = const UsersManagementView();
        break;
      case 2:
        child = const BranchesRoomsView();
        break;
      case 3:
        child = const AdmissionsCrmView();
        break;
      case 4:
        child = const CourseListScreen(showAppBar: false);
        break;
      case 5:
        child = const ClassListScreen(showAppBar: false);
        break;
      case 6:
        child = const TeacherAttendanceView();
        break;
      case 7:
        child = const ReportsOverviewScreen(showAppBar: false);
        break;
      case 8:
        child = const SystemSettingsView();
        break;
      default:
        child = const AdminDashboardScreen(showAppBar: false);
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
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!user.isSuperAdmin &&
            !user.isBranchAdmin &&
            !user.isAcademicStaff &&
            !user.isCashier) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go(user.dashboardRoute ?? RouteNames.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (isDesktop) {
          // ==================== WEB DESKTOP PORTAL LAYOUT ====================
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Row(
              children: [
                // Persistent Sidebar (260px)
                Material(
                  color: Theme.of(context).cardColor,
                  child: Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.neutral200),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Sidebar Header & Brand
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.neutral200),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'EduLMS',
                                              style: AppTextStyles.h4(context)
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                          'Hệ thống Đào tạo Ngoại ngữ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Quick Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openCreateClassFromShell,
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Mở Lớp Học Mới'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Navigation list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            itemCount: _navItems.length,
                            itemBuilder: (context, index) {
                              final item = _navItems[index];
                              final isSelected = _selectedIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _selectNavTab(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          size: 20,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 13,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimaryLight,
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
                                              color: AppColors.error.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              item['badge'] as String,
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
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

                        // Sidebar Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.neutral200),
                            ),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Hotline kỹ thuật: 1900-8888 (24/7)',
                                      ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.support_agent_rounded,
                                        size: 20,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                      SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          'Hỗ trợ kỹ thuật',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => context.read<AuthBloc>().add(
                                  LogoutRequestedEvent(),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Đăng xuất',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content Canvas
                Expanded(
                  child: Column(
                    children: [
                      // Top Header Bar
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.neutral200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _navItems[_selectedIndex]['title'] as String,
                                style: AppTextStyles.h4(context)
                                    .copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Global Search Input
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 40,
                                  constraints: const BoxConstraints(
                                    minWidth: 80,
                                    maxWidth: 360,
                                  ),
                                  child:
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable:
                                            _globalSearchController,
                                        builder: (context, value, _) {
                                          final isCompactDesktop =
                                              MediaQuery.of(context)
                                                  .size
                                                  .width <=
                                              1100;
                                          return TextField(
                                            controller: _globalSearchController,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: isCompactDesktop
                                                  ? 'Tìm kiếm...'
                                                  : 'Tìm kiếm nhanh học viên, lớp học, hóa đơn...',
                                              hintStyle: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.neutral400,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                size: 18,
                                                color: AppColors.neutral500,
                                              ),
                                              suffixIcon: value.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 16,
                                                        color: AppColors
                                                            .neutral500,
                                                      ),
                                                      tooltip: 'Xóa tìm kiếm',
                                                      onPressed: () =>
                                                          _globalSearchController
                                                              .clear(),
                                                    )
                                                  : null,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              filled: true,
                                              fillColor: AppColors.neutral100,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primary,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Branch Selector
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.neutral200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'CN 1: Quận 1',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const NotificationBellIcon(),
                            const SizedBox(width: 16),
                            // User Profile Avatar & Name
                            InkWell(
                              onTap: () => context.push(RouteNames.profile),
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (MediaQuery.of(context).size.width >
                                      1100) ...[
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          user.isSuperAdmin
                                              ? 'Super Admin'
                                              : 'Quản trị chi nhánh',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Canvas Body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox.expand(child: _buildActiveBody()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // ==================== MOBILE LAYOUT (Pixel 9 / Android) ====================
          return Scaffold(
            appBar: AppBar(
              title: Text(_navItems[_selectedIndex]['title'] as String),
              actions: [
                const NotificationBellIcon(),
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  tooltip: 'Hồ sơ',
                  onPressed: () => context.push(RouteNames.profile),
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: AppColors.primary),
                    accountName: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(user.email ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  ..._navItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSel = _selectedIndex == idx;

                    return ListTile(
                      selected: isSel,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSel
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        _selectNavTab(idx);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(LogoutRequestedEvent());
                    },
                  ),
                ],
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox.expand(child: _buildActiveBody()),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: switch (_selectedIndex) {
                5 => 1,
                4 => 2,
                7 => 3,
                _ => 0,
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondaryLight,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Tổng quan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'Lớp học',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_rounded),
                  label: 'Khóa học',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Báo cáo',
                ),
              ],
              onTap: (idx) {
                switch (idx) {
                  case 0:
                    _selectNavTab(0);
                    break;
                  case 1:
                    _selectNavTab(5); // Classes
                    break;
                  case 2:
                    _selectNavTab(4); // Courses
                    break;
                  case 3:
                    _selectNavTab(7); // Reports
                    break;
                }
              },
            ),
          );
        }
      },
    );
  }
}
