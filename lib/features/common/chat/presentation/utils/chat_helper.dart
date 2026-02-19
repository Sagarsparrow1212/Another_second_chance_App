import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../providers/chat_providers.dart';
import '../../../../common/auth/data/services/auth_storage_service.dart';

class ChatHelper {
  /// Start a chat with a user (organization and homeless)
  /// Returns the chat ID if successful, null if error
  static Future<String?> startChat({
    required WidgetRef ref,
    required BuildContext context,
    required String organizationId,
    required String homelessId,
    String? organizationName,
    String? homelessName,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: AppLoader()),
      );

      // Get or create chat
      final useCase = ref.read(chatUseCaseProvider);
      final chat = await useCase.getOrCreateChat(organizationId, homelessId);

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat
      if (context.mounted) {
        context.push('/chat/${chat.id}');
      }

      return chat.id;
    } catch (e) {
      // Close loading indicator if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  static Future<String?> startChatMerchant({
    required WidgetRef ref,
    required BuildContext context,
    required String merchantId,
    required String homelessId,
    String? merchantName,
    String? homelessName,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: AppLoader()),
      );

      // Get or create chat
      final useCase = ref.read(chatUseCaseProvider);
      final chat = await useCase.getOrCreateMerchantChat(
        merchantId,
        homelessId,
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat
      if (context.mounted) {
        context.push('/chat/${chat.id}');
      }

      return chat.id;
    } catch (e) {
      // Close loading indicator if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  /// Start a chat from current user's role
  /// Automatically determines organization/homeless IDs based on current user
  static Future<String?> startChatWithUser({
    required WidgetRef ref,
    required BuildContext context,
    required String targetUserId,
    String? targetUserName,
  }) async {
    try {
      final userRole = await AuthStorageService.getUserRole();
      String? currentUserId;
      print("targetUserID: $targetUserId");
      if (userRole == 'organization') {
        // Get organization ID from organizationBox
        final organizationBox = await Hive.openBox('organizationBox');
        currentUserId = organizationBox.get('organizationId')?.toString();
      } else if (userRole == 'homeless') {
        // Get homeless ID from homelessBox
        final homelessBox = await Hive.openBox('homelessBox');
        currentUserId = homelessBox.get('homelessId')?.toString();
      } else if (userRole == 'merchant') {
        // Get merchant ID from merchantBox
        final merchantBox = await Hive.openBox('merchantBox');
        currentUserId = merchantBox.get('merchantId')?.toString();
      } else {
        throw Exception(
          'Chat is only available for organization and homeless users',
        );
      }

      if (currentUserId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      if (userRole == 'organization') {
        // Current user is organization, target is homeless
        return await startChat(
          ref: ref,
          context: context,
          organizationId: currentUserId,
          homelessId: targetUserId,
          homelessName: targetUserName,
        );
      } else if (userRole == 'homeless') {
        // Current user is homeless, target is organization
        return await startChat(
          ref: ref,
          context: context,
          organizationId: targetUserId,
          homelessId: currentUserId,
          organizationName: targetUserName,
        );
      } else if (userRole == 'merchant') {
        // Current user is merchant, target is homeless
        return await startChatMerchant(
          ref: ref,
          context: context,
          merchantId: currentUserId,
          homelessId: targetUserId,
          homelessName: targetUserName,
        );
      } else {
        throw Exception(
          'Chat is only available for organization and homeless users',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }
}
