import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> updateFcmToken(String token);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiClient apiClient;

  NotificationsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int limit = 20, bool? isRead}) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (isRead != null) {
      queryParams['isRead'] = isRead;
    }

    final response = await apiClient.get(
      ApiEndpoints.myNotifications,
      queryParameters: queryParams,
    );

    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    if (data is Map<String, dynamic>) {
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } else if (data is List<dynamic>) {
      return data.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await apiClient.get(ApiEndpoints.unreadNotificationsCount);
    final data = response is Map<String, dynamic> ? (response['data'] ?? response) : response;
    if (data is Map<String, dynamic>) {
      return (data['count'] as num?)?.toInt() ?? 0;
    } else if (data is num) {
      return data.toInt();
    }
    return 0;
  }

  @override
  Future<void> markAsRead(String id) async {
    await apiClient.patch(ApiEndpoints.markNotificationAsRead(id));
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.post(ApiEndpoints.markAllNotificationsAsRead);
  }

  @override
  Future<void> updateFcmToken(String token) async {
    await apiClient.put(
      ApiEndpoints.updateFcmToken,
      data: {'token': token},
    );
  }
}
