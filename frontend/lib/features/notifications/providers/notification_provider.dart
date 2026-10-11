import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationState {
  final bool isLoading;
  final List<dynamic> notifications;
  final int unreadCount;
  final String? latestAlertTitle;

  NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.latestAlertTitle,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<dynamic>? notifications,
    int? unreadCount,
    String? latestAlertTitle,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      latestAlertTitle: latestAlertTitle ?? this.latestAlertTitle,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;
  IO.Socket? _socket;

  NotificationNotifier(this.ref) : super(NotificationState()) {
    initSocketAndFetch();
  }

  final Dio _dio = DioClient.instance;

  void initSocketAndFetch() {
    fetchNotifications();
    _connectSocket();
  }

  void _connectSocket() {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;

      _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        // Join personalized channels
        _socket?.emit('join:user', user.id);
        _socket?.emit('join:role', user.role);
        if (user.assignedClass != null) {
          final classId = user.assignedClass is Map ? user.assignedClass['_id'] : user.assignedClass;
          _socket?.emit('join:class', classId);
        }
      });

      _socket?.on('notification:new', (data) {
        if (data != null) {
          final title = data['title'] ?? 'New School Alert';
          final currentList = [data, ...state.notifications];
          state = state.copyWith(
            notifications: currentList,
            unreadCount: state.unreadCount + 1,
            latestAlertTitle: title,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _dio.get(ApiConstants.myNotifications);
      final list = res.data['data'] as List<dynamic>? ?? [];
      final unread = list.where((n) => n['isRead'] != true).length;

      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch('${ApiConstants.myNotifications.replaceAll('/my', '')}/$notificationId/read');
      final updated = state.notifications.map((n) {
        if (n['_id'] == notificationId) {
          return {...n, 'isRead': true};
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
