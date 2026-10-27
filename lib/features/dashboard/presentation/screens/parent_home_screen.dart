import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_card.dart';
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
