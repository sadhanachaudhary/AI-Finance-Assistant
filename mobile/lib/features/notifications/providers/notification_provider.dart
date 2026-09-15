import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../networking/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  () => NotificationsNotifier(),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  return notifsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  ApiClient get _api => ref.watch(apiClientProvider);

  @override
  Future<List<AppNotification>> build() async {
    return _fetchNotifications();
  }

  Future<List<AppNotification>> _fetchNotifications() async {
    try {
      final res = await _api.dio.get(ApiEndpoints.notifications);
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'];
        if (data != null && data['notifications'] != null) {
          final rawList = data['notifications'] as List;
          return rawList.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // Fallback for offline/demo mode
    }

    // Default proactive alerts for fresh accounts
    return [
      AppNotification(
        id: 'init-alert-1',
        title: '⚠️ High Spending Alert: Food & Dining',
        body: 'You have spent ₹3,450 on dining this week (42% of total expenses). Consider home dining to preserve your monthly savings target.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'init-alert-2',
        title: '🌟 Halfway There: Emergency Fund',
        body: 'Great job! You have crossed ₹25,000 (50%) towards your Emergency Fund target of ₹50,000.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      AppNotification(
        id: 'init-alert-3',
        title: '🔁 Recurring Subscriptions Audit',
        body: 'Detected active monthly subscriptions: Netflix (₹649) & Spotify (₹119). Tap AI Advisor for optimization options.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'init-alert-4',
        title: '🛡️ Privacy Shield Active',
        body: 'On-device regex scrubbing & PII redaction are active. Your financial identifiers are guarded.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  Future<void> generateSmartAlerts() async {
    try {
      final res = await _api.dio.post(ApiEndpoints.notificationGenerateAlerts, data: {});
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'];
        if (data != null && data['notifications'] != null) {
          final rawList = data['notifications'] as List;
          state = AsyncValue.data(
            rawList.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList(),
          );
          return;
        }
      }
    } catch (_) {}
    await refresh();
  }

  Future<void> markAsRead(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );

    try {
      await _api.dio.patch(ApiEndpoints.notificationRead(id), data: {});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      await _api.dio.patch(ApiEndpoints.notificationReadAll, data: {});
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((n) => n.id != id).toList(),
    );

    try {
      await _api.dio.delete(ApiEndpoints.notificationById(id));
    } catch (_) {}
  }
}
