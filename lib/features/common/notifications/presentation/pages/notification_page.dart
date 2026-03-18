import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import '../manager/notification_provider.dart';
import '../widgets/notification_tile.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsyncValue = ref.watch(notificationProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Notifications', showBackButton: true),
      body: notificationAsyncValue.when(
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading notifications'),
              TextButton(
                onPressed: () {
                  ref.invalidate(notificationProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(notificationProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () async {
                    if (!notification.isRead) {
                      try {
                        await ref
                            .read(notificationRepositoryProvider)
                            .markAsRead(notification.id);
                        // Refresh the list to show updated status
                        ref.invalidate(notificationProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to mark as read'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }

                    if (!context.mounted) return;

                    // Handle navigation
                    final type = notification.type.toLowerCase();
                    if (type == 'donation') {
                      final role = await AuthStorageService.getUserRole();
                      if (!context.mounted) return;

                      if (role == 'homeless') {
                        context.go('/homeless/my-donations');
                      } else if (role == 'organization') {
                        context.go('/organization/donation-history');
                      } else if (role == 'donor') {
                        context.go('/donor/my-donations');
                      }
                    } else if (type.contains('job') ||
                        notification.title.toLowerCase().contains('job')) {
                      final role = await AuthStorageService.getUserRole();
                      if (!context.mounted) return;

                      if (role == 'homeless') {
                        context.go('/homeless/jobs');
                      } else if (role == 'organization') {
                        context.go('/organization/jobs');
                      } else if (role == 'merchant') {
                        context.go('/merchant/jobs');
                      }
                    } else if (type == 'chat' || type == 'message') {
                      final role = await AuthStorageService.getUserRole();
                      if (!context.mounted) return;

                      if (role == 'organization') {
                        context.go('/organization/chat');
                      } else if (role == 'homeless') {
                        context.go('/homeless/chat');
                      } else if (role == 'merchant') {
                        context.go('/merchant/chat');
                      } else {
                        context.go('/chat');
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
