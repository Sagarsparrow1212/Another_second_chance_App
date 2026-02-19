import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notification_repository.dart';
import 'package:homelyhope/features/common/notifications/data/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.fetchNotifications();
    });
