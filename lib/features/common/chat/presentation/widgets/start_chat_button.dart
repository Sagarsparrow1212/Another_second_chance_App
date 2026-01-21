import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/chat_helper.dart';

/// A reusable button to start a chat with a user
class StartChatButton extends ConsumerWidget {
  final String targetUserId;
  final String? targetUserName;
  final IconData? icon;
  final String? label;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isIconButton;

  const StartChatButton({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.icon,
    this.label,
    this.backgroundColor,
    this.iconColor,
    this.isIconButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isIconButton) {
      return IconButton(
        onPressed: () => _startChat(context, ref),
        icon: FaIcon(
          icon ?? FontAwesomeIcons.message,
          color: iconColor ?? Colors.blue,
        ),
        tooltip: label ?? 'Start Chat',
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _startChat(context, ref),
      icon: FaIcon(icon ?? FontAwesomeIcons.message, size: 16),
      label: Text(label ?? 'Chat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    await ChatHelper.startChatWithUser(
      ref: ref,
      context: context,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
    );
  }
}

/// A simple icon button for starting chat (compact version)
class ChatIconButton extends ConsumerWidget {
  final String targetUserId;
  final String? targetUserName;
  final Color? color;

  const ChatIconButton({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StartChatButton(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      isIconButton: true,
      iconColor: color ?? Colors.blue,
    );
  }
}
