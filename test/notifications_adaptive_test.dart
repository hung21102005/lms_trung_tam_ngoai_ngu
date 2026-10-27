import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/data/models/notification_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/notifications/presentation/screens/notification_list_screen.dart';

class _Notifications implements NotificationsRepository {
  bool markedAll = false;

  @override
  Future<List<NotificationModel>> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async => [
    NotificationModel(
      id: 'n1',
      userId: 's1',
      title: 'Lịch học mới',
      body: 'Buổi học Speaking practice',
      type: 'ACADEMIC',
      isRead: markedAll,
      createdAt: DateTime(2026, 10, 27),
    ),
  ];

  @override
  Future<int> getUnreadCount() async => markedAll ? 0 : 1;

  @override
  Future<void> markAllAsRead() async => markedAll = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('thông báo thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Notifications();
      final bloc = NotificationBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: NotificationListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lịch học mới'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notifications-mobile')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      if (width < 600) {
        await tester.tap(find.byTooltip('Đánh dấu đã đọc tất cả'));
        await tester.pumpAndSettle();
        expect(repository.markedAll, isTrue);
        expect(find.text('0 thông báo chưa đọc'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
