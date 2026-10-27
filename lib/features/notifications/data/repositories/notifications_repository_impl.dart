import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead}) {
    return remoteDataSource.getMyNotifications(page: page, limit: limit, isRead: isRead);
  }

  @override
  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String id) {
    return remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> updateFcmToken(String token) {
    return remoteDataSource.updateFcmToken(token);
  }
}
