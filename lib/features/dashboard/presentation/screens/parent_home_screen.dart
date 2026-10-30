import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        final user = state is AuthenticatedState ? state.user : null;

        if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
            AdaptiveSize.mobile) {
          return _ParentMobileHome(user: user);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Góc Phụ Huynh'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Đăng xuất',
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequestedEvent());
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  color: const Color(0xFF6366F1), // Indigo
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.family_restroom_rounded,
                          color: Color(0xFF6366F1),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phụ huynh: ${user?.fullName ?? ""}',
                              style: AppTextStyles.h3(context)
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              'SĐT: ${user?.phone ?? ""}',
                              style: AppTextStyles.bodySmall(context)
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Theo Dõi Con Em', style: AppTextStyles.h3(context)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.sizeOf(context).width > 600
                      ? 1.4
                      : 1.15,
                  children: [
                    _buildItem(
                      context,
                      Icons.calendar_month_rounded,
                      'Lịch Học Của Con',
                      Colors.indigo,
                      onTap: () => context.push(RouteNames.schedule),
                    ),
                    _buildItem(
                      context,
                      Icons.child_care_rounded,
                      'Danh Sách Con Em',
                      Colors.blue,
                      onTap: () => _showChildren(context),
                    ),
                    _buildItem(
                      context,
                      Icons.checklist_rtl_rounded,
                      'Theo Dõi Điểm Danh',
                      Colors.green,
                      onTap: () => _showChildren(context, openAttendance: true),
                    ),
                    _buildItem(
                      context,
                      Icons.auto_graph_rounded,
                      'Bảng Điểm & Nhận Xét',
                      Colors.orange,
                    ),
                    _buildItem(
                      context,
                      Icons.payment_rounded,
                      'Thanh Toán Học Phí',
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChildren(
    BuildContext context, {
    bool openAttendance = false,
  }) async {
    try {
      if (!getIt.isRegistered<ClassesRepository>()) return;
      final classes = await getIt<ClassesRepository>().getMyClasses();
      if (!context.mounted) return;
      final children = <String, String>{};
      for (final item in classes) {
        for (final student in item.students) {
          if (student.status == 'ENROLLED' && student.studentId.isNotEmpty) {
            children[student.studentId] =
                student.studentName ?? student.studentCode ?? 'Học viên';
          }
        }
      }

      if (children.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có học viên được liên kết trong lớp học.'),
          ),
        );
        return;
      }
      if (openAttendance && children.length == 1) {
        context.push(RouteNames.myAttendance, extra: children.keys.first);
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  'Con em của bạn',
                  style: AppTextStyles.h3(sheetContext),
                ),
              ),
              for (final child in children.entries)
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(child.value),
                  subtitle: const Text('Xem lịch sử chuyên cần'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(RouteNames.myAttendance, extra: child.key);
                  },
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tải được danh sách con em. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentMobileHome extends StatefulWidget {
  const _ParentMobileHome({required this.user});

  final UserEntity? user;

  @override
  State<_ParentMobileHome> createState() => _ParentMobileHomeState();
}

class _ParentMobileHomeState extends State<_ParentMobileHome> {
  late Future<List<ClassModel>> _classes;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _classes = getIt.isRegistered<ClassesRepository>()
        ? getIt<ClassesRepository>().getMyClasses()
        : Future.value([]);
  }

  Future<void> _openAttendanceFlow(
    BuildContext context,
    List<ClassModel> classes,
  ) async {
    final children = <String, String>{};
    for (final item in classes) {
      for (final student in item.students) {
        if (student.status == 'ENROLLED' && student.studentId.isNotEmpty) {
          children[student.studentId] =
              student.studentName ?? student.studentCode ?? 'Học viên';
        }
      }
    }

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có học viên được liên kết trong lớp học.'),
        ),
      );
      return;
    }

    if (children.length == 1) {
      context.push(RouteNames.myAttendance, extra: children.keys.first);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Text(
                'Con em của bạn',
                style: AppTextStyles.h3(sheetContext),
              ),
            ),
            for (final child in children.entries)
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(child.value),
                subtitle: const Text('Xem lịch sử chuyên cần'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RouteNames.myAttendance, extra: child.key);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Góc Phụ Huynh'),
      actions: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.push(RouteNames.notifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          tooltip: 'Hồ sơ cá nhân',
          onPressed: () => context.push(RouteNames.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
    ),
    backgroundColor: const Color(0xFFF8FAFC),
    body: FutureBuilder<List<ClassModel>>(
      future: _classes,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không tải được thông tin con em.'),
                TextButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final children = <String, String>{};
        final classesByChild = <String, List<ClassModel>>{};
        for (final studyClass in snapshot.data!) {
          for (final student in studyClass.students) {
            if (student.status != 'ENROLLED' || student.studentId.isEmpty) {
              continue;
            }
            children[student.studentId] =
                student.studentName ?? student.studentCode ?? 'Học viên';
            classesByChild
                .putIfAbsent(student.studentId, () => [])
                .add(studyClass);
          }
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _classes;
          },
          child: ListView(
            key: const ValueKey('parent-home-mobile'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              Text(
                'Xin chào, ${widget.user?.fullName ?? 'Phụ huynh'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Theo dõi việc học của con tại EduLMS.',
                style: TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 18),
              MobileSectionCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.family_restroom_outlined,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${children.length} con được liên kết',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${snapshot.data!.length} lớp đang theo dõi',
                            style: const TextStyle(color: AppColors.neutral600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.schedule),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Xem lịch học của con'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => _openAttendanceFlow(context, snapshot.data ?? []),
                icon: const Icon(Icons.checklist_rtl_rounded),
                label: const Text('Theo Dõi Điểm Danh'),
              ),
              const SizedBox(height: 20),
              Text(
                'Con em của tôi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (children.isEmpty)
                const MobileSectionCard(
                  child: Text('Chưa có học viên được liên kết trong lớp học.'),
                ),
              for (final child in children.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MobileSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                child.value.isEmpty
                                    ? '?'
                                    : child.value[0].toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                child.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final studyClass
                            in classesByChild[child.key] ?? [])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${studyClass.name}',
                              style: const TextStyle(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            RouteNames.myAttendance,
                            extra: child.key,
                          ),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Xem chuyên cần'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(LogoutRequestedEvent()),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
