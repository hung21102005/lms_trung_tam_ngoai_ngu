import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../views/student_gradebook_view.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../notifications/presentation/screens/notification_list_screen.dart';
import '../../../classes/presentation/screens/schedule_screen.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../courses/presentation/screens/student_courses_screen.dart';
import '../../../finance/presentation/screens/my_invoices_screen.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../assignments/presentation/screens/student_assignments_view.dart';
import '../views/student_course_discovery_view.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late Future<List<ClassSessionModel>> _upcomingSchedule;
  int _selectedIndex = 0;
  final TextEditingController _globalSearchController = TextEditingController();

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Trang chủ', 'icon': Icons.dashboard_rounded, 'badge': null},
    {'title': 'Lịch học', 'icon': Icons.calendar_month_rounded, 'badge': null},
    {'title': 'Khóa học của tôi', 'icon': Icons.school_rounded, 'badge': null},
    {'title': 'Khám phá & Đăng ký', 'icon': Icons.explore_rounded, 'badge': 'Mới'},
    {'title': 'Bài tập', 'icon': Icons.assignment_rounded, 'badge': null},
    {'title': 'Học phí', 'icon': Icons.receipt_long_rounded, 'badge': null},
    {'title': 'Bảng điểm', 'icon': Icons.military_tech_rounded, 'badge': null},
    {'title': 'Thông báo', 'icon': Icons.notifications_rounded, 'badge': null},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    context.read<ClassesBloc>().add(const FetchMyClasses());
    final today = DateTime.now();
    _upcomingSchedule = getIt.isRegistered<ClassesRepository>()
        ? getIt<ClassesRepository>().getMySchedule(
            fromDate: DateFormat('yyyy-MM-dd').format(today),
            toDate: DateFormat('yyyy-MM-dd')
                .format(today.add(const Duration(days: 60))),
          )
        : Future.value([]);
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop =
        AdaptiveBreakpoints.fromWidth(size.width) == AdaptiveSize.desktop;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        final user = state is AuthenticatedState ? state.user : null;
        if (user != null && !user.isStudent) {
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
            backgroundColor: AppColors.background(context),
            body: Row(
              children: [
                _buildDesktopSidebar(context, user),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context, user),
                      Expanded(
                        child: Container(
                          color: AppColors.background(context),
                          child: SizedBox.expand(
                            child: _buildActiveBody(user, true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ==================== MOBILE LAYOUT (Android Pixel 9) ====================
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
                tooltip: 'Hồ sơ',
                onPressed: () => context.push(RouteNames.profile),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: _buildMobileDrawer(context, user),
          body: SizedBox.expand(child: _buildActiveBody(user, false)),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: switch (_selectedIndex) {
              0 => 0,
              1 => 1,
              2 || 3 => 2,
              4 => 3,
              5 => 4,
              _ => 0,
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface(context),
            selectedItemColor: AppColors.primaryOf(context),
            unselectedItemColor: AppColors.textMuted(context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Lịch học',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_rounded),
                label: 'Khóa học',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Bài tập',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Học phí',
              ),
            ],
            onTap: (idx) {
              setState(() {
                _selectedIndex = switch (idx) {
                  0 => 0,
                  1 => 1,
                  2 => 2,
                  3 => 4,
                  4 => 5,
                  _ => 0,
                };
              });
            },
          ),
        );
      },
    );
  }

  // ==================== DESKTOP SIDEBAR ====================
  Widget _buildDesktopSidebar(BuildContext context, UserEntity? user) {
    final primaryBtn = AppColors.isDark(context)
        ? AppColors.primaryLight
        : AppColors.primary;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(right: BorderSide(color: AppColors.border(context))),
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
                    color: primaryBtn,
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
                              color: AppColors.brandBg(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'v2.4',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryOf(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Cổng Học Viên',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border(context)),
          // Quick Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4; // Bài tập
                  });
                },
                icon: const Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  '+ Nộp bài tập ngay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtn,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // Navigation Items List
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
                            ? primaryBtn
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
                                : AppColors.textSecondary(context),
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
                                    : AppColors.textPrimary(context),
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
                                    : AppColors.warningBg(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.warningFg(context),
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
          Divider(height: 1, color: AppColors.border(context)),
          // Student Profile Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brandBg(context),
                  child: Text(
                    user != null && user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'H',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Học viên LMS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.userCode ?? 'HV-2026-0001',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.errorFg(context),
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

  // ==================== DESKTOP HEADER ====================
  Widget _buildDesktopHeader(BuildContext context, UserEntity? user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_outlined,
                  color: AppColors.primaryOf(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _navItems[_selectedIndex]['title'] as String,
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
          // Global Search Field
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 40,
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 360),
                child: TextField(
                  controller: _globalSearchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: MediaQuery.of(context).size.width <= 1100
                        ? 'Tìm kiếm...'
                        : 'Tìm khóa học, bài tập, lịch học...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: AppColors.surfaceSubtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Term / Semester Selector
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandBg(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primaryOf(context),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      user?.branchName ?? 'Học Kỳ 1 - 2026',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryOf(context),
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
          // Student Profile Avatar & Name
          InkWell(
            onTap: () => context.push(RouteNames.profile),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brandBg(context),
                  child: Text(
                    user != null && user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'H',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                    ),
                  ),
                ),
                if (MediaQuery.of(context).size.width > 1100) ...[
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Học viên LMS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user?.userCode ?? 'Học viên chính thức',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
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
    );
  }

  // ==================== MOBILE DRAWER ====================
  Widget _buildMobileDrawer(BuildContext context, UserEntity? user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(
              user?.fullName ?? 'Học viên LMS',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              '${user?.userCode ?? "HV-2026-0001"} • ${user?.branchName ?? "Chi nhánh Quận 1"}',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user != null && user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'H',
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
                        ? AppColors.primaryOf(context)
                        : AppColors.textSecondary(context),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primaryOf(context)
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  trailing: item['badge'] != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['badge'] as String,
                            style: TextStyle(
                              color: AppColors.warningFg(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: AppColors.brandBg(context),
                  onTap: () {
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
            leading: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary(context),
            ),
            title: const Text('Hồ sơ cá nhân'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.profile);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.errorFg(context)),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.errorFg(context),
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

  // ==================== ACTIVE BODY SWITCHER ====================
  Widget _buildActiveBody(UserEntity? user, bool isDesktop) {
    Widget child;
    switch (_selectedIndex) {
      case 0:
        child = _buildOverviewContent(user, isDesktop);
        break;
      case 1:
        child = BlocProvider<ClassesBloc>(
          create: (_) => getIt<ClassesBloc>(),
          child: const ScheduleScreen(showAppBar: false),
        );
        break;
      case 2:
        child = const StudentCoursesScreen();
        break;
      case 3:
        child = const StudentCourseDiscoveryView();
        break;
      case 4:
        child = const StudentAssignmentsView();
        break;
      case 5:
        child = BlocProvider<FinanceBloc>(
          create: (_) => getIt<FinanceBloc>(),
          child: const MyInvoicesScreen(),
        );
        break;
      case 6:
        child = const StudentGradebookView();
        break;
      case 7:
        child = const NotificationListScreen();
        break;
      default:
        child = _buildOverviewContent(user, isDesktop);
    }
    return KeyedSubtree(key: ValueKey<int>(_selectedIndex), child: child);
  }

  // ==================== TAB 0: OVERVIEW ====================
  Widget _buildOverviewContent(UserEntity? user, bool isDesktop) {
    if (!isDesktop) return _buildMobileOverviewContent(user);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Student Hero Profile Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'H',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào học viên,',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.fullName ?? 'Học viên LMS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Mã HV: ${user?.userCode ?? "HV-2026-0001"} • ${user?.branchName ?? "Chi nhánh Quận 1"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () => context.push(RouteNames.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Quick Action Shortcuts
          Text(
            'Lối Tắt Học Tập',
            style: AppTextStyles.h4(context)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.35 : 1.2,
            children: [
              _buildShortcutCard(
                icon: Icons.calendar_today_rounded,
                title: 'Thời Khóa Biểu',
                desc: 'Xem lịch học trong tuần',
                color: Colors.blue,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _buildShortcutCard(
                icon: Icons.menu_book_rounded,
                title: 'Khóa Học & Tài Liệu',
                desc: 'Bài giảng & giáo trình',
                color: Colors.orange,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _buildShortcutCard(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Bài Tập Về Nhà',
                desc: 'Nộp phát âm & bài viết',
                color: Colors.green,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildShortcutCard(
                icon: Icons.receipt_long_rounded,
                title: 'Học Phí & VNPay',
                desc: 'Hóa đơn & thanh toán online',
                color: Colors.purple,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Upcoming Class Session Card (Live Connected)
          FutureBuilder<List<ClassSessionModel>>(
            future: _upcomingSchedule,
            builder: (context, snapshot) {
              final nextSession = snapshot.hasData
                  ? _findNextSession(snapshot.data!)
                  : null;

              if (nextSession == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      snapshot.hasError
                          ? 'Không tải được lịch học.'
                          : snapshot.connectionState != ConnectionState.done
                          ? 'Đang tải buổi học tiếp theo...'
                          : 'Chưa có buổi học sắp tới.',
                    ),
                  ),
                );
              }

              final className =
                  nextSession.className ?? nextSession.classCode ?? 'Lớp học';
              final topic = nextSession.lessonTitle ?? nextSession.title;
              final room =
                  nextSession.roomName ??
                  nextSession.roomCode ??
                  'Chưa xếp phòng';
              final teacher = nextSession.teacherName != null
                  ? 'GV: ${nextSession.teacherName}'
                  : 'Chưa phân công giáo viên';
              final timeStr =
                  '${DateFormat('dd/MM').format(nextSession.date!)} • ${nextSession.startTime} - ${nextSession.endTime}';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.primaryOf(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Buổi Học Tiếp Theo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandBg(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                timeStr,
                                style: TextStyle(
                                  color: AppColors.primaryOf(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Lớp: $className',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chủ đề: $topic',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  room,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  teacher,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ClassSessionModel? _findNextSession(List<ClassSessionModel> sessions) {
    final now = DateTime.now();
    for (final session in sessions) {
      final date = session.date;
      if (date == null || session.status == 'CANCELLED') continue;
      final parts = session.endTime.split(':');
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(parts.first) ?? 23,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59,
      );
      if (end.isAfter(now)) return session;
    }
    return null;
  }

  Widget _buildMobileOverviewContent(UserEntity? user) {
    return ListView(
      key: const ValueKey('student-mobile-dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Xin chào, ${user?.fullName ?? 'học viên'} 👋',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Cùng tiếp tục hành trình học tập hôm nay.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        FutureBuilder<List<ClassSessionModel>>(
          future: _upcomingSchedule,
          builder: (context, snapshot) {
            final next = snapshot.hasData
                ? _findNextSession(snapshot.data!)
                : null;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Buổi học tiếp theo',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    next == null
                        ? snapshot.hasError
                              ? 'Chưa tải được lịch học'
                              : snapshot.connectionState != ConnectionState.done
                              ? 'Đang tải lịch học...'
                              : 'Chưa có buổi học sắp tới'
                        : next.className ?? next.classCode ?? 'Lớp học',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('dd/MM').format(next.date!)} · '
                      '${next.startTime}–${next.endTime}'
                      '${next.roomName == null ? '' : ' · ${next.roomName}'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Xem lịch học'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        const Text(
          'Học tập nhanh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _mobileQuickAction(
                Icons.calendar_month_rounded,
                'Lịch học',
                AppColors.primary,
                1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _mobileQuickAction(
                Icons.school_rounded,
                'Khóa học',
                AppColors.secondary,
                2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _mobileQuickAction(
                Icons.assignment_rounded,
                'Bài tập',
                AppColors.warning,
                3,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _mobileQuickAction(
                Icons.receipt_long_rounded,
                'Học phí',
                AppColors.primaryLight,
                4,
              ),
            ),
          ],
        ),
        const SizedBox(height: MobileTokens.sectionGap),
        MobileSectionCard(
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppColors.primaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hồ sơ học viên',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      user?.userCode ?? 'Xem thông tin cá nhân',
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mở hồ sơ',
                onPressed: () => context.push(RouteNames.profile),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileQuickAction(
    IconData icon,
    String label,
    Color color,
    int index,
  ) {
    final adaptedColor = AppColors.adaptAccent(context, color);
    return MobileSectionCard(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: adaptedColor, size: 27),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 17,
              color: AppColors.textMuted(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    final adaptedColor = AppColors.adaptAccent(context, color);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: adaptedColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: adaptedColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
