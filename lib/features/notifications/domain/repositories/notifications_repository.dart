import '../../data/models/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> updateFcmToken(String token);
}
