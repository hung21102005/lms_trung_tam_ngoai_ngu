import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/models/notification_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/screens/notification_list_screen.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  final List<NotificationModel> _mockItems = [
    NotificationModel(
      id: 'notif-1',
      userId: 'user-1',
      title: 'Học phí mới phát hành',
      body: 'Hóa đơn học phí IELTS Foundation đã được tạo.',
      type: 'TUITION',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'notif-2',
      userId: 'user-1',
      title: 'Thông báo vắng học',
      body: 'Bạn được ghi nhận vắng mặt buổi 2.',
      type: 'ATTENDANCE',
      isRead: true,
      readAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead}) async {
    if (isRead != null) {
      return _mockItems.where((n) => n.isRead == isRead).toList();
    }
    return _mockItems;
  }

  @override
  Future<int> getUnreadCount() async {
    return _mockItems.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> updateFcmToken(String token) async {}
}

void main() {
  testWidgets('NotificationListScreen renders notifications and filter tabs', (tester) async {
    final fakeRepo = FakeNotificationsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: fakeRepo),
          child: const NotificationListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title & Actions
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Đọc tất cả'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Học phí'), findsOneWidget);
    expect(find.text('Điểm danh'), findsOneWidget);

    // Verify Notification items
    expect(find.text('Học phí mới phát hành'), findsOneWidget);
    expect(find.text('Thông báo vắng học'), findsOneWidget);
  });

  testWidgets('Filter tab switches properly', (tester) async {
    final fakeRepo = FakeNotificationsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: fakeRepo),
          child: const NotificationListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Học phí' tab
    await tester.tap(find.text('Học phí'));
    await tester.pumpAndSettle();

    expect(find.text('Học phí mới phát hành'), findsOneWidget);
    expect(find.text('Thông báo vắng học'), findsNothing);
  });
}
