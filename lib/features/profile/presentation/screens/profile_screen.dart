import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart' as app_err;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = getIt<ApiClient>();

  int _activeWebTab = 0; // 0: Thông tin cá nhân, 1: Bảo mật & Mật khẩu, 2: Phân quyền & Hoạt động

  // Inline Edit Profile Controllers (for Web Desktop)
  final _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  String? _selectedGender;
  String? _populatedUserId;

  // Inline Change Password Controllers (for Web Desktop)
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Preferences toggles
  bool _notifyScheduleAndAssignments = true;
  bool _notifyEmailLoginAlert = true;
  bool _autoLockIdleWebSession = true;
  bool _biometricMobileEnabled = false;

  // Dữ liệu thống kê thực tế theo vai trò của tài khoản đang đăng nhập (Không dùng số giả định)
  String? _statsLoadedForUserId;
  int _teacherActiveClasses = 0;
  int _teacherTotalClasses = 0;
  int _teacherTotalStudents = 0;
  int _studentActiveClasses = 0;
  int _studentCompletedClasses = 0;
  int _studentPendingRegistrations = 0;
  String? _studentCurrentClassName;
  int _parentLinkedChildren = 0;
  int _parentChildrenActiveClasses = 0;
  int _adminScopedUsers = 0;
  int _adminScopedBranches = 0;
  int _adminScopedClasses = 0;
  int _adminScopedCourses = 0;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void reassemble() {
    super.reassemble();
    _statsLoadedForUserId = null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      final data = res['data'];
      if (data is List) return data;
      if (data is Map) {
        if (data['items'] is List) return data['items'] as List;
        if (data['data'] is List) return data['data'] as List;
      }
      if (res['items'] is List) return res['items'] as List;
    }
    return [];
  }

  int _intStat(Map<String, dynamic> stats, String key, int fallback) {
    final val = stats[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  Future<void> _fetchRoleScopedStats(UserEntity user, {bool force = false}) async {
    if (!force && _statsLoadedForUserId == user.id) return;
    _statsLoadedForUserId = user.id;

    final stats = user.linkedStats;
    if (stats.isNotEmpty) {
      if (mounted) {
        setState(() {
          _teacherActiveClasses = _intStat(stats, 'activeClassesCount', 0);
          _teacherTotalClasses = _intStat(stats, 'totalClassesCount', 0);
          _teacherTotalStudents = _intStat(stats, 'totalStudentsCount', 0);
          _studentActiveClasses = _intStat(stats, 'activeClassesCount', 0);
          _studentCompletedClasses = _intStat(stats, 'completedClassesCount', 0);
          _studentPendingRegistrations =
              _intStat(stats, 'pendingRegistrationsCount', 0);
          _parentLinkedChildren = _intStat(stats, 'linkedChildrenCount', 0);
          _parentChildrenActiveClasses =
              _intStat(stats, 'childrenActiveClassesCount', 0);
          _adminScopedUsers = _intStat(stats, 'scopedUsersCount', 0);
          _adminScopedBranches = _intStat(stats, 'scopedBranchesCount', 0);
          _adminScopedClasses = _intStat(stats, 'scopedClassesCount', 0);
          _adminScopedCourses = _intStat(stats, 'scopedCoursesCount', 0);
        });
      }
    }

    try {
      if (user.isTeacher) {
        final res = await _apiClient
            .get('/classes/my-classes')
            .catchError((_) => <String, dynamic>{});
        final myClasses = _extractList(res).whereType<Map>().toList();
        if (myClasses.isNotEmpty || stats.isEmpty) {
          final active = myClasses.where((c) {
            final st = c['status']?.toString().toUpperCase() ?? '';
            return st == 'PLANNING' ||
                st == 'OPEN_FOR_ENROLLMENT' ||
                st == 'IN_PROGRESS';
          }).length;
          final nonCancelled = myClasses.where((c) {
            final st = c['status']?.toString().toUpperCase() ?? '';
            return st != 'CANCELLED';
          }).length;
          int studentsSum = 0;
          for (final c in myClasses) {
            final countObj = c['_count'];
            if (countObj is Map && countObj['students'] is num) {
              studentsSum += (countObj['students'] as num).toInt();
            } else if (c['enrolledCount'] is num) {
              studentsSum += (c['enrolledCount'] as num).toInt();
            } else if (c['currentStudents'] is num) {
              studentsSum += (c['currentStudents'] as num).toInt();
            }
          }
          if (mounted) {
            setState(() {
              _teacherActiveClasses = stats.containsKey('activeClassesCount')
                  ? _intStat(stats, 'activeClassesCount', active)
                  : active;
              _teacherTotalClasses = stats.containsKey('totalClassesCount')
                  ? _intStat(stats, 'totalClassesCount', nonCancelled)
                  : nonCancelled;
              _teacherTotalStudents = stats.containsKey('totalStudentsCount')
                  ? _intStat(stats, 'totalStudentsCount', studentsSum)
                  : studentsSum;
            });
          }
        }
      } else if (user.isStudent) {
        final res = await _apiClient
            .get('/classes/my-classes')
            .catchError((_) => <String, dynamic>{});
        final myClasses = _extractList(res).whereType<Map>().toList();
        if (myClasses.isNotEmpty || stats.isEmpty) {
          final activeList = myClasses.where((c) {
            final st = c['status']?.toString().toUpperCase() ?? '';
            return st != 'CANCELLED' && st != 'COMPLETED';
          }).toList();
          final completedCount = myClasses.where((c) {
            final st = c['status']?.toString().toUpperCase() ?? '';
            return st == 'COMPLETED';
          }).length;
          if (mounted) {
            setState(() {
              _studentActiveClasses = stats.containsKey('activeClassesCount')
                  ? _intStat(stats, 'activeClassesCount', activeList.length)
                  : activeList.length;
              _studentCompletedClasses =
                  stats.containsKey('completedClassesCount')
                      ? _intStat(stats, 'completedClassesCount', completedCount)
                      : completedCount;
              if (activeList.isNotEmpty) {
                _studentCurrentClassName = activeList.first['name']?.toString();
              }
            });
          }
        }
      } else if (user.isSuperAdmin ||
          user.isBranchAdmin ||
          user.isAcademicStaff ||
          user.isCashier) {
        if (stats.isEmpty) {
          final results = await Future.wait([
            _apiClient
                .get('/users', queryParameters: {'limit': 100})
                .catchError((_) => <String, dynamic>{}),
            _apiClient.get('/branches').catchError((_) => <String, dynamic>{}),
            _apiClient
                .get('/classes', queryParameters: {'limit': 100})
                .catchError((_) => <String, dynamic>{}),
            _apiClient
                .get('/courses', queryParameters: {'limit': 100})
                .catchError((_) => <String, dynamic>{}),
          ]);
          final users = _extractList(results[0]);
          final branches = _extractList(results[1]);
          final classes = _extractList(results[2]);
          final courses = _extractList(results[3]);
          if (mounted) {
            setState(() {
              _adminScopedUsers = users.length;
              _adminScopedBranches = branches.length;
              _adminScopedClasses = classes.length;
              _adminScopedCourses = courses.length;
            });
          }
        }
      }
    } catch (_) {}
  }

  String _getBranchDisplayName(UserEntity user) {
    final name = user.branchName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (user.isSuperAdmin || user.isTeacher) {
      return 'Liên cơ sở (Toàn hệ thống)';
    }
    return 'Chưa phân bổ chi nhánh cố định';
  }

  int _getTeacherActiveClasses(UserEntity user) =>
      _intStat(user.linkedStats, 'activeClassesCount', _teacherActiveClasses);

  int _getTeacherTotalClasses(UserEntity user) =>
      _intStat(user.linkedStats, 'totalClassesCount', _teacherTotalClasses);

  int _getTeacherTotalStudents(UserEntity user) =>
      _intStat(user.linkedStats, 'totalStudentsCount', _teacherTotalStudents);

  int _getStudentActiveClasses(UserEntity user) =>
      _intStat(user.linkedStats, 'activeClassesCount', _studentActiveClasses);

  int _getStudentCompletedClasses(UserEntity user) => _intStat(
        user.linkedStats,
        'completedClassesCount',
        _studentCompletedClasses,
      );

  int _getStudentPendingRegistrations(UserEntity user) => _intStat(
        user.linkedStats,
        'pendingRegistrationsCount',
        _studentPendingRegistrations,
      );

  int _getParentLinkedChildren(UserEntity user) =>
      _intStat(user.linkedStats, 'linkedChildrenCount', _parentLinkedChildren);

  int _getParentChildrenActiveClasses(UserEntity user) => _intStat(
        user.linkedStats,
        'childrenActiveClassesCount',
        _parentChildrenActiveClasses,
      );

  int _getAdminUsers(UserEntity user) =>
      _intStat(user.linkedStats, 'scopedUsersCount', _adminScopedUsers);

  int _getAdminBranches(UserEntity user) =>
      _intStat(user.linkedStats, 'scopedBranchesCount', _adminScopedBranches);

  int _getAdminClasses(UserEntity user) =>
      _intStat(user.linkedStats, 'scopedClassesCount', _adminScopedClasses);

  int _getAdminCourses(UserEntity user) =>
      _intStat(user.linkedStats, 'scopedCoursesCount', _adminScopedCourses);

  void _syncControllersWithUser(UserEntity user) {
    if (_populatedUserId != user.id) {
      _populatedUserId = user.id;
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phone ?? '';
      _addressCtrl.text = user.address ?? '';
      _selectedGender = user.gender;
    }
  }

  String _getRoleDisplayName(UserEntity user) {
    if (user.isSuperAdmin) return 'Super Admin • Quản trị viên Hệ thống';
    if (user.isBranchAdmin) return 'Branch Admin • Quản lý Cơ sở';
    if (user.isAcademicStaff) return 'Chuyên viên Học vụ & Tuyển sinh';
    if (user.isTeacher) return 'Giảng viên Đào tạo (Teacher)';
    if (user.isParent) return 'Phụ huynh Học viên';
    return 'Học viên Chính thức (Student)';
  }

  String _getRoleStatusBadge(UserEntity user) {
    if (user.isSuperAdmin || user.isBranchAdmin || user.isAcademicStaff) {
      return 'Đang công tác trực tuyến';
    }
    if (user.isTeacher) {
      return 'Đang giảng dạy';
    }
    return 'Đang theo học';
  }

  String _getRoleCodeLabel(UserEntity user) {
    if (user.isSuperAdmin || user.isBranchAdmin || user.isAcademicStaff) {
      return 'Mã nhân sự: ${user.userCode}';
    }
    if (user.isTeacher) {
      return 'Mã giảng viên: ${user.teacherCode ?? user.userCode}';
    }
    return 'Mã học viên: ${user.studentCode ?? user.userCode}';
  }

  String _getRoleSubtitle(UserEntity user) {
    if (user.isSuperAdmin) {
      return 'Ban Quản trị Hệ thống • Toàn quyền điều hành CSDL';
    }
    if (user.isBranchAdmin || user.isAcademicStaff || user.isCashier) {
      return 'Phòng Quản lý Học vụ • ${_getBranchDisplayName(user)}';
    }
    if (user.isTeacher) {
      final activeCount = _getTeacherActiveClasses(user);
      final totalCount = _getTeacherTotalClasses(user);
      if (activeCount == 0 && totalCount == 0) {
        return 'Khoa Đào tạo Ngoại ngữ • Phụ trách 0 lớp học (Chưa phân công lớp)';
      }
      return 'Khoa Đào tạo Ngoại ngữ • Phụ trách $activeCount lớp hoạt động (Tổng $totalCount lớp)';
    }
    if (user.isParent) {
      final childrenCount = _getParentLinkedChildren(user);
      return 'Phụ huynh học viên • Liên kết $childrenCount học viên';
    }
    final activeClass = user.currentClass ?? _studentCurrentClassName;
    return activeClass != null && activeClass.isNotEmpty
        ? 'Lớp đang học: $activeClass'
        : 'Chưa xếp lớp cố định';
  }

  void _submitInlineProfileUpdate() {
    if (_profileFormKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
            UpdateProfileEvent(
              fullName: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              gender: _selectedGender,
            ),
          );
    }
  }

  void _submitInlinePasswordChange() {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
            ChangePasswordSubmittedEvent(
              currentPassword: _currentPassCtrl.text,
              newPassword: _newPassCtrl.text,
              confirmPassword: _confirmPassCtrl.text,
            ),
          );
    }
  }

  void _showQrIdentityDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: Color(0xFF003FB1)),
            SizedBox(width: 8),
            Text('Mã Định Danh Điện Tử EduLMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 160, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                '${_getRoleCodeLabel(user)} • ${user.email ?? ""}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF047857),
            ),
          );
        } else if (state is ProfilePasswordChangeSuccess) {
          _currentPassCtrl.clear();
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF047857),
            ),
          );
          context.read<ProfileBloc>().add(const LoadProfileEvent());
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FF),
            body: LoadingWidget(message: 'Đang tải thông tin hồ sơ từ cơ sở dữ liệu...'),
          );
        }

        if (state is ProfileError && state.user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            appBar: AppBar(title: const Text('Tài khoản & Cá nhân')),
            body: app_err.AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<ProfileBloc>().add(const LoadProfileEvent()),
            ),
          );
        }

        final user = state is ProfileLoaded
            ? state.user
            : (state is ProfileUpdating
                ? state.currentUser
                : (state is ProfileError ? state.user : null));

        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            appBar: AppBar(title: const Text('Tài khoản & Cá nhân')),
            body: Center(
              child: ElevatedButton.icon(
                onPressed: () => context.read<ProfileBloc>().add(const LoadProfileEvent()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại hồ sơ cá nhân'),
              ),
            ),
          );
        }

        _syncControllersWithUser(user);
        _fetchRoleScopedStats(user);

        if (isDesktop) {
          return _buildWebDesktopScaffold(context, user, state);
        }
        return _buildMobileScaffold(context, user);
      },
    );
  }

  // ===========================================================================
  // 1. WEBSITE / DESKTOP VIEW (Synchronized with Stitch Portal Theme)
  // ===========================================================================
  Widget _buildWebDesktopScaffold(BuildContext context, UserEntity user, ProfileState state) {
    final isUpdating = state is ProfileUpdating || state is ProfilePasswordChanging;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Column(
        children: [
          // Top Navigation Bar matching Admin/Teacher/Student Portal Header
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(user.dashboardRoute ?? RouteNames.login);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 17, color: Color(0xFF0F172A)),
                  label: const Text('Quay lại Bảng điều khiển'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 20),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 20),
                const Icon(Icons.manage_accounts_rounded, color: Color(0xFF003FB1), size: 22),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Hồ sơ Cá nhân & Bảo mật Tài khoản',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        _getRoleStatusBadge(user),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    context.read<ProfileBloc>().add(const LoadProfileEvent());
                    _fetchRoleScopedStats(user, force: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Làm mới dữ liệu hồ sơ',
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 17, color: Color(0xFFDC2626)),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Main Centered Workspace Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Page Heading Banner
                      Container(
                        padding: const EdgeInsets.only(bottom: 18),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, ${user.fullName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.h2(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hôm nay: $todayStr • Quản lý thông tin định danh, mật khẩu bảo mật và quyền hạn truy cập trên hệ thống Web Portal',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                              ],
                            )),
                            ElevatedButton.icon(
                              onPressed: isUpdating
                                  ? null
                                  : () {
                                      if (_activeWebTab == 0) {
                                        _submitInlineProfileUpdate();
                                      } else if (_activeWebTab == 1) {
                                        _submitInlinePasswordChange();
                                      } else {
                                        setState(() => _activeWebTab = 0);
                                      }
                                    },
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                _activeWebTab == 1 ? 'Cập nhật mật khẩu' : '+ Lưu thông tin hồ sơ',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003FB1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2-Column Proportional Grid (Left 4 / Right 8)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT COLUMN: Identity Card + Real Stats + Session Info
                          Expanded(
                            flex: 4,
                            child: _buildWebLeftColumn(context, user),
                          ),
                          const SizedBox(width: 24),

                          // RIGHT COLUMN: Tabbed Workspace (Profile Form / Password & Security / RBAC)
                          Expanded(
                            flex: 8,
                            child: _buildWebRightColumn(context, user, isUpdating),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLeftColumn(BuildContext context, UserEntity user) {
    final branchTitle = _getBranchDisplayName(user);
    final rolesCount = user.roles.isNotEmpty ? user.roles.length : 1;

    late final String stat1Label;
    late final String stat1Value;
    late final IconData stat1Icon;
    late final String stat2Label;
    late final String stat2Value;
    late final IconData stat2Icon;
    late final String stat3Label;
    late final String stat3Value;
    late final IconData stat3Icon;

    if (user.isTeacher) {
      stat1Label = 'Lớp đang phụ trách';
      stat1Value = '${_getTeacherActiveClasses(user)} lớp';
      stat1Icon = Icons.class_rounded;
      stat2Label = 'Tổng lớp giảng dạy';
      stat2Value = '${_getTeacherTotalClasses(user)} lớp';
      stat2Icon = Icons.fact_check_rounded;
      stat3Label = 'Học viên phụ trách';
      stat3Value = '${_getTeacherTotalStudents(user)} HV';
      stat3Icon = Icons.groups_rounded;
    } else if (user.isStudent) {
      stat1Label = 'Lớp đang theo học';
      stat1Value = '${_getStudentActiveClasses(user)} lớp';
      stat1Icon = Icons.school_rounded;
      stat2Label = 'Lớp đã hoàn thành';
      stat2Value = '${_getStudentCompletedClasses(user)} lớp';
      stat2Icon = Icons.task_alt_rounded;
      stat3Label = 'Đăng ký chờ duyệt';
      stat3Value = '${_getStudentPendingRegistrations(user)} ĐK';
      stat3Icon = Icons.pending_actions_rounded;
    } else if (user.isParent) {
      stat1Label = 'Học viên liên kết';
      stat1Value = '${_getParentLinkedChildren(user)} HV';
      stat1Icon = Icons.family_restroom_rounded;
      stat2Label = 'Lớp con đang học';
      stat2Value = '${_getParentChildrenActiveClasses(user)} lớp';
      stat2Icon = Icons.class_rounded;
      stat3Label = 'Cơ sở theo học';
      stat3Value = user.branchName != null ? '1 cơ sở' : 'Liên cơ sở';
      stat3Icon = Icons.domain_rounded;
    } else {
      stat1Label = 'Người dùng phạm vi';
      stat1Value = '${_getAdminUsers(user)} TK';
      stat1Icon = Icons.groups_rounded;
      stat2Label = 'Cơ sở hoạt động';
      stat2Value = '${_getAdminBranches(user)} cơ sở';
      stat2Icon = Icons.domain_rounded;
      stat3Label = 'Lớp trong phạm vi';
      stat3Value = '${_getAdminClasses(user)} lớp';
      stat3Icon = Icons.class_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Proportional Digital Identity Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Top Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003FB1), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Flexible(child: Text(
                              'THẺ ĐỊNH DANH EDULMS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ))),
                          ],
                        )),
                        InkWell(
                          onTap: () => _showQrIdentityDialog(user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.qr_code_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Mã QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withAlpha(40),
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRoleDisplayName(user),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Account Info Details List
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.badge_outlined, 'Mã định danh', user.userCode),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.email_outlined, 'Email đăng nhập', user.email ?? 'Chưa cập nhật'),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', user.phone ?? 'Chưa cập nhật'),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(Icons.apartment_rounded, 'Cơ sở trực thuộc', branchTitle),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(
                      Icons.verified_rounded,
                      'Trạng thái tài khoản',
                      user.status == 'ACTIVE' ? 'Đang hoạt động (ACTIVE)' : user.status,
                      valueColor: const Color(0xFF047857),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Real System Metrics Card (Role-aware, 100% Real DB Numbers)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Color(0xFF003FB1), size: 19),
                  SizedBox(width: 8),
                  Flexible(child: Text(
                    'Thông Số Liên Kết Thực Tế',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                  )),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatBox(
                      label: stat1Label,
                      value: stat1Value,
                      icon: stat1Icon,
                      color: const Color(0xFF003FB1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatBox(
                      label: stat2Label,
                      value: stat2Value,
                      icon: stat2Icon,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatBox(
                      label: stat3Label,
                      value: stat3Value,
                      icon: stat3Icon,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMiniStatBox(
                      label: 'Vai trò đảm nhiệm',
                      value: '$rolesCount vai trò',
                      icon: Icons.shield_outlined,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Web Session Info Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF003FB1), size: 19),
                  SizedBox(width: 8),
                  Flexible(child: Text(
                    'Phiên Làm Việc Website Hiện Tại',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  )),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '• Nền tảng: EduLMS Web Portal (Desktop Browser)\n'
                '• Phương thức xác thực: JWT Bearer Token (HTTPS/REST)\n'
                '• Xác thực sinh trắc học: Đã ẩn tự động (Chỉ áp dụng trên ứng dụng di động iOS/Android)',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebRightColumn(BuildContext context, UserEntity user, bool isUpdating) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal Tabs Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildWebTabButton(0, 'Thông tin hồ sơ & Liên hệ', Icons.person_outline_rounded),
                  _buildWebTabButton(1, 'Bảo mật & Đổi mật khẩu', Icons.lock_outline_rounded),
                  _buildWebTabButton(2, 'Phân quyền vai trò & Thiết lập thông báo', Icons.admin_panel_settings_outlined),
                ],
              ),
            ),
          ),

          // Tab Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: _activeWebTab == 0
                ? _buildWebProfileFormTab(user, isUpdating)
                : (_activeWebTab == 1
                    ? _buildWebSecurityAndPasswordTab(isUpdating)
                    : _buildWebPermissionsAndNotificationsTab(user)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabButton(int index, String label, IconData icon) {
    final isSelected = _activeWebTab == index;
    return InkWell(
      onTap: () => setState(() => _activeWebTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 28),
        padding: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF003FB1) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? const Color(0xFF003FB1) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF003FB1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEB TAB 0: INLINE EDIT PROFILE FORM
  // ---------------------------------------------------------------------------
  Widget _buildWebProfileFormTab(UserEntity user, bool isUpdating) {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông Tin Cá Nhân & Hồ Sơ Định Danh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cập nhật họ tên, số điện thoại liên hệ và địa chỉ thường trú trực tiếp trên hệ thống',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 15, color: Color(0xFF047857)),
                    SizedBox(width: 4),
                    Text(
                      'Đã đồng bộ CSDL',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 1: Full Name + User Code (Read-only)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên đầy đủ *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Họ và tên không được để trống' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: user.userCode,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Mã định danh tài khoản',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Email (Read-only) + Phone
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: user.email ?? 'Chưa cập nhật',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ Email đăng nhập',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại liên hệ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Gender + Branch
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: (_selectedGender == 'MALE' || _selectedGender == 'FEMALE' || _selectedGender == 'OTHER')
                      ? _selectedGender
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    prefixIcon: Icon(Icons.wc_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: _getBranchDisplayName(user),
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Cơ sở đào tạo / Công tác',
                    prefixIcon: Icon(Icons.domain_rounded),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 4: Address
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ liên hệ / Thường trú',
              hintText: 'Nhập số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố...',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Role / Department Info Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF003FB1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getRoleSubtitle(user),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        _populatedUserId = null;
                        _syncControllersWithUser(user);
                        setState(() {});
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: const Text('Hoàn tác'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isUpdating ? null : _submitInlineProfileUpdate,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(isUpdating ? 'Đang lưu...' : 'Lưu thông tin cá nhân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEB TAB 1: INLINE PASSWORD CHANGE & WEB SECURITY SETTINGS (No Biometrics!)
  // ---------------------------------------------------------------------------
  Widget _buildWebSecurityAndPasswordTab(bool isUpdating) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đổi Mật Khẩu Đăng Nhập Tài Khoản',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mật khẩu mới cần có tối thiểu 6 ký tự và không trùng với mật khẩu đang sử dụng.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _currentPassCtrl,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Mật khẩu hiện tại *',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureCurrent = !(_obscureCurrent)),
              ),
            ),
            validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newPassCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới *',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureNew = !(_obscureNew)),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Mật khẩu mới phải từ 6 ký tự trở lên';
                    }
                    if (val == _currentPassCtrl.text) {
                      return 'Mật khẩu mới không được trùng mật khẩu cũ';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới *',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !(_obscureConfirm)),
                    ),
                  ),
                  validator: (val) =>
                      (val != _newPassCtrl.text) ? 'Mật khẩu xác nhận không khớp' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isUpdating ? null : _submitInlinePasswordChange,
              icon: const Icon(Icons.key_rounded, size: 18),
              label: Text(isUpdating ? 'Đang cập nhật...' : 'Xác nhận đổi mật khẩu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003FB1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const Divider(height: 36, color: Color(0xFFE2E8F0)),

          const Text(
            'Tùy Chọn Bảo Mật Phiên Đăng Nhập Trình Duyệt (Web Security)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notifyEmailLoginAlert,
            activeThumbColor: const Color(0xFF003FB1),
            title: const Text(
              'Gửi cảnh báo qua Email khi tài khoản đăng nhập trên trình duyệt hoặc máy tính mới',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Giúp phát hiện sớm truy cập trái phép vào cổng quản trị Web Portal.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _notifyEmailLoginAlert = v),
          ),
          const Divider(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoLockIdleWebSession,
            activeThumbColor: const Color(0xFF003FB1),
            title: const Text(
              'Tự động khóa phiên làm việc trên trình duyệt khi không thao tác sau 30 phút',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Đảm bảo an toàn dữ liệu khi bạn rời khỏi bàn làm việc.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _autoLockIdleWebSession = v),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEB TAB 2: PERMISSIONS & NOTIFICATION SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildWebPermissionsAndNotificationsTab(UserEntity user) {
    final effectiveRoles = user.roles.isNotEmpty ? user.roles : ['user'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vai Trò & Phạm Vi Quyền Hạn Trên Hệ Thống (RBAC)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Danh sách các vai trò và quyền hạn được cấp cho tài khoản của bạn:',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: effectiveRoles.map((role) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF003FB1)),
                  const SizedBox(width: 8),
                  Text(
                    'Vai trò: ${role.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003FB1)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),

        const Text(
          'Cấu Hình Nhận Thông Báo Trên Website',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _notifyScheduleAndAssignments,
          activeThumbColor: const Color(0xFF003FB1),
          title: const Text(
            'Hiển thị thông báo thời gian thực (Lịch học, Điểm danh, Bài tập & Hóa đơn)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Cập nhật trực tiếp tại biểu tượng chuông thông báo trên thanh công cụ.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          onChanged: (v) => setState(() => _notifyScheduleAndAssignments = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. MOBILE APP VIEW (`width <= 900`)
  // ===========================================================================
  Widget _buildMobileScaffold(BuildContext context, UserEntity user) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Tài khoản & Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa hồ sơ',
            onPressed: () => context.push(RouteNames.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded),
            tooltip: 'Đổi mật khẩu',
            onPressed: () => context.push(RouteNames.changePassword),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. SMART DIGITAL ID CARD (Role-aware)
            _buildMobileDigitalIdCard(context, user),
            const SizedBox(height: 16),

            // 2. REAL STATS ROW
            _buildMobileStatsRow(context, user),
            const SizedBox(height: 20),

            // 3. GROUP 1: HỒ SƠ & ĐỊNH DANH
            _buildSectionTitle(context, 'Hồ sơ & Định danh'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.badge_outlined,
                    iconColor: AppColors.primary,
                    title: 'Thông tin cá nhân & Liên hệ',
                    subtitle: '${user.email ?? "Chưa cập nhật email"} • ${user.phone ?? "Chưa có SĐT"}',
                    trailing: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    onTap: () => context.push(RouteNames.editProfile),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.domain_rounded,
                    iconColor: Colors.deepPurple,
                    title: 'Cơ sở trực thuộc',
                    subtitle: _getBranchDisplayName(user),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. GROUP 2: CÀI ĐẶT & BẢO MẬT
            _buildSectionTitle(context, 'Cài đặt & Bảo mật'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // ONLY SHOW BIOMETRICS ON NATIVE MOBILE (!kIsWeb)
                  if (!kIsWeb) ...[
                    _buildMenuItem(
                      context,
                      icon: Icons.fingerprint_rounded,
                      iconColor: Colors.teal,
                      title: 'Đăng nhập sinh trắc học (FaceID / Vân tay)',
                      trailing: Switch(
                        value: _biometricMobileEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _biometricMobileEnabled = val),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.blueAccent,
                    title: 'Thông báo lịch học & Bài tập mới',
                    trailing: Switch(
                      value: _notifyScheduleAndAssignments,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _notifyScheduleAndAssignments = val),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_outline_rounded,
                    iconColor: Colors.indigo,
                    title: 'Đổi mật khẩu tài khoản',
                    onTap: () => context.push(RouteNames.changePassword),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. LOGOUT BUTTON
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                kIsWeb
                    ? 'EduLMS Web Portal v2.4 • Bản quyền thuộc EduLMS Vietnam'
                    : 'EduLMS Mobile v2.4.0 • Bản quyền thuộc EduLMS Vietnam',
                style: AppTextStyles.caption(context).copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDigitalIdCard(BuildContext context, UserEntity user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (user.isSuperAdmin || user.isBranchAdmin || user.isAcademicStaff)
                            ? Icons.admin_panel_settings_rounded
                            : (user.isTeacher ? Icons.menu_book_rounded : Icons.school_rounded),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        user.isSuperAdmin
                            ? 'EDULMS SUPER ADMIN'
                            : (user.isBranchAdmin || user.isAcademicStaff
                                ? 'EDULMS ADMIN PASS'
                                : (user.isTeacher ? 'EDULMS FACULTY CARD' : 'EDULMS SMART CARD')),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRoleStatusBadge(user),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withAlpha(40),
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? const Icon(Icons.person_rounded, size: 36, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleCodeLabel(user),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRoleDisplayName(user),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showQrIdentityDialog(user),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: Color(0xFF0F172A),
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Cơ sở: ${_getBranchDisplayName(user)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                'Niên khóa 2026 - 2027',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatsRow(BuildContext context, UserEntity user) {
    late final String col1Val;
    late final String col1Label;
    late final IconData col1Icon;
    late final String col2Val;
    late final String col2Label;
    late final IconData col2Icon;
    late final String col3Val;
    late final String col3Label;
    late final IconData col3Icon;

    if (user.isTeacher) {
      col1Val = '${_getTeacherActiveClasses(user)}';
      col1Label = 'Lớp phụ trách';
      col1Icon = Icons.class_rounded;
      col2Val = '${_getTeacherTotalStudents(user)}';
      col2Label = 'Học viên';
      col2Icon = Icons.groups_rounded;
      col3Val = '${_getTeacherTotalClasses(user)}';
      col3Label = 'Tổng lớp dạy';
      col3Icon = Icons.fact_check_rounded;
    } else if (user.isStudent) {
      col1Val = '${_getStudentActiveClasses(user)}';
      col1Label = 'Lớp đang học';
      col1Icon = Icons.school_rounded;
      col2Val = '${_getStudentCompletedClasses(user)}';
      col2Label = 'Đã hoàn thành';
      col2Icon = Icons.task_alt_rounded;
      col3Val = '${_getStudentPendingRegistrations(user)}';
      col3Label = 'Chờ xếp lớp';
      col3Icon = Icons.pending_actions_rounded;
    } else if (user.isParent) {
      col1Val = '${_getParentLinkedChildren(user)}';
      col1Label = 'Con liên kết';
      col1Icon = Icons.family_restroom_rounded;
      col2Val = '${_getParentChildrenActiveClasses(user)}';
      col2Label = 'Lớp đang học';
      col2Icon = Icons.class_rounded;
      col3Val = '${user.roles.isNotEmpty ? user.roles.length : 1}';
      col3Label = 'Vai trò';
      col3Icon = Icons.shield_outlined;
    } else {
      col1Val = '${_getAdminCourses(user)}';
      col1Label = 'Khóa đào tạo';
      col1Icon = Icons.menu_book_rounded;
      col2Val = '${_getAdminClasses(user)}';
      col2Label = 'Lớp hoạt động';
      col2Icon = Icons.fact_check_rounded;
      col3Val = '${_getAdminBranches(user)}';
      col3Label = 'Chi nhánh';
      col3Icon = Icons.apartment_rounded;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatColumn(
              context,
              col1Val,
              col1Label,
              col1Icon,
              AppColors.primary,
            ),
          ),
          Container(height: 36, width: 1, color: AppColors.borderLight),
          Expanded(
            child: _buildStatColumn(
              context,
              col2Val,
              col2Label,
              col2Icon,
              AppColors.success,
            ),
          ),
          Container(height: 36, width: 1, color: AppColors.borderLight),
          Expanded(
            child: _buildStatColumn(
              context,
              col3Val,
              col3Label,
              col3Icon,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.h3(context).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTextStyles.caption(context).copyWith(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.h4(context).copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.caption(context).copyWith(color: AppColors.textSecondaryLight),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight)
              : null),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống EduLMS không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthBloc>().add(LogoutRequestedEvent());
              context.go(RouteNames.login);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
