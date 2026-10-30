import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/notifications_repository.dart';

// EVENTS
abstract class NotificationEvent {}

class FetchNotificationsEvent extends NotificationEvent {
  final int page;
  final bool? isRead;

  FetchNotificationsEvent({this.page = 1, this.isRead});
}

class FetchUnreadCountEvent extends NotificationEvent {}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String id;

  MarkNotificationAsReadEvent(this.id);
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {}

class RegisterFcmTokenEvent extends NotificationEvent {
  final String token;

  RegisterFcmTokenEvent(this.token);
}

// STATES
abstract class NotificationState {}

class NotificationInitialState extends NotificationState {}

class NotificationLoadingState extends NotificationState {}

class NotificationLoadedState extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationLoadedState({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationLoadedState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoadedState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationErrorState extends NotificationState {
  final String message;

  NotificationErrorState(this.message);
}

// BLOC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationsRepository repository;

  NotificationBloc({required this.repository}) : super(NotificationInitialState()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<FetchUnreadCountEvent>(_onFetchUnreadCount);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<RegisterFcmTokenEvent>(_onRegisterFcmToken);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoadingState());
    try {
      final notifications = await repository.getMyNotifications(
        page: event.page,
        isRead: event.isRead,
      );
      final unreadCount = await repository.getUnreadCount();
      emit(NotificationLoadedState(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationErrorState(e.toString()));
    }
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCountEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final unreadCount = await repository.getUnreadCount();
      if (state is NotificationLoadedState) {
        final current = state as NotificationLoadedState;
        emit(current.copyWith(unreadCount: unreadCount));
      } else {
        emit(NotificationLoadedState(notifications: const [], unreadCount: unreadCount));
      }
    } catch (_) {}
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      try {
        await repository.markAsRead(event.id);
        final updatedList = current.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();
        final newUnread = current.unreadCount > 0 ? current.unreadCount - 1 : 0;
        emit(current.copyWith(notifications: updatedList, unreadCount: newUnread));
      } catch (e) {
        // Ignored or keep current state
      }
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      try {
        await repository.markAllAsRead();
        final updatedList = current.notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();
        emit(current.copyWith(notifications: updatedList, unreadCount: 0));
      } catch (e) {
        // Ignored
      }
    }
  }

  Future<void> _onRegisterFcmToken(
    RegisterFcmTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.updateFcmToken(event.token);
    } catch (_) {}
  }
}
