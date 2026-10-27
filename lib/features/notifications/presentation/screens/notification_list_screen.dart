import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notification_bloc.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filters = ['Tất cả', 'Chưa đọc', 'Học phí', 'Điểm danh', 'Đề thi', 'Học vụ'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    context.read<NotificationBloc>().add(FetchNotificationsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllNotificationsAsReadEvent());
            },
            icon: const Icon(Icons.done_all, size: 20),
            label: const Text('Đọc tất cả'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoadingState) {
            return const LoadingWidget();
          }

          if (state is NotificationErrorState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(FetchNotificationsEvent());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoadedState) {
            final filtered = _filterNotifications(state.notifications, _filters[_tabController.index]);

            if (filtered.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(FetchNotificationsEvent());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    const EmptyStateWidget(
                      icon: Icons.notifications_off_outlined,
                      title: 'Không có thông báo nào',
                      description: 'Bạn đã xem hết các thông báo trong danh mục này.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(FetchNotificationsEvent());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notif = filtered[index];
                  return _buildNotificationCard(notif);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> list, String filter) {
    switch (filter) {
      case 'Chưa đọc':
        return list.where((n) => !n.isRead).toList();
      case 'Học phí':
        return list.where((n) => n.type == 'TUITION').toList();
      case 'Điểm danh':
        return list.where((n) => n.type == 'ATTENDANCE').toList();
      case 'Đề thi':
        return list.where((n) => n.type == 'EXAM').toList();
      case 'Học vụ':
        return list.where((n) => n.type == 'ACADEMIC').toList();
      default:
        return list;
    }
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final config = _getNotificationConfig(notif.type);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!notif.isRead) {
          context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(notif.id));
        }
        _handleNotificationTap(notif);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : config.color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead ? AppColors.borderLight : config.color.withAlpha(80),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: config.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          config.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: config.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(notif.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                      if (!notif.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: notif.isRead ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    if (notif.type == 'TUITION') {
      context.push(RouteNames.myInvoices);
    } else if (notif.type == 'EXAM') {
      context.push(RouteNames.myExamResults);
    } else if (notif.type == 'ATTENDANCE') {
      context.push(RouteNames.myAttendance);
    } else if (notif.type == 'ACADEMIC') {
      context.push(RouteNames.schedule);
    }
  }

  _NotifConfig _getNotificationConfig(String type) {
    switch (type) {
      case 'TUITION':
        return _NotifConfig(
          label: 'HỌC PHÍ',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFFD97706), // Amber dark
        );
      case 'ATTENDANCE':
        return _NotifConfig(
          label: 'ĐIỂM DANH',
          icon: Icons.event_busy_outlined,
          color: const Color(0xFFDC2626), // Red
        );
      case 'EXAM':
        return _NotifConfig(
          label: 'BÀI THI',
          icon: Icons.quiz_outlined,
          color: const Color(0xFF7C3AED), // Purple
        );
      case 'ACADEMIC':
        return _NotifConfig(
          label: 'HỌC VỤ',
          icon: Icons.school_outlined,
          color: const Color(0xFF2563EB), // Blue
        );
      default:
        return _NotifConfig(
          label: 'HỆ THỐNG',
          icon: Icons.notifications_none_outlined,
          color: const Color(0xFF4B5563), // Gray
        );
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}

class _NotifConfig {
  final String label;
  final IconData icon;
  final Color color;

  _NotifConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
