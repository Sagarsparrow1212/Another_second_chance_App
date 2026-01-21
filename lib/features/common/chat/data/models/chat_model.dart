import 'package:homelyhope/core/contanst/contanst.dart';

class ChatModel {
  final String id;
  final ChatUser? organization;
  final ChatUser? homeless;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;

  ChatModel({
    required this.id,
    this.organization,
    this.homeless,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    ChatUser? organization;
    try {
      final orgData = json['organization'] ?? json['organizationId'];
      if (orgData != null) {
        if (orgData is Map) {
          organization = ChatUser.fromJson(Map<String, dynamic>.from(orgData));
        } else if (orgData is String) {
          organization = ChatUser(id: orgData);
        } else {}
      }
    } catch (e, stackTrace) {
      // Try to get just the ID
      try {
        final orgId = json['organizationId'] is Map
            ? (json['organizationId'] as Map)['_id'] ??
                  (json['organizationId'] as Map)['id']
            : json['organization'] is Map
            ? (json['organization'] as Map)['_id'] ??
                  (json['organization'] as Map)['id']
            : null;
        if (orgId != null) {
          organization = ChatUser(id: orgId.toString());
        }
      } catch (e2) {}
    }

    // Handle homeless - API may return 'homeless' or 'homelessId'
    ChatUser? homeless;
    try {
      final homelessData = json['homeless'] ?? json['homelessId'];
      if (homelessData != null) {
        if (homelessData is Map) {
          homeless = ChatUser.fromJson(Map<String, dynamic>.from(homelessData));
        } else if (homelessData is String) {
          homeless = ChatUser(id: homelessData);
        } else {}
      }
    } catch (e, stackTrace) {
      // Try to get just the ID
      try {
        final homelessId = json['homelessId'] is Map
            ? (json['homelessId'] as Map)['_id'] ??
                  (json['homelessId'] as Map)['id']
            : json['homeless'] is Map
            ? (json['homeless'] as Map)['_id'] ??
                  (json['homeless'] as Map)['id']
            : null;
        if (homelessId != null) {
          homeless = ChatUser(id: homelessId.toString());
        }
      } catch (e2) {}
    }

    // Handle lastMessage - could be a full object, an ID string, or null
    MessageModel? lastMessage;
    try {
      final lastMsgData = json['lastMessage'];
      if (lastMsgData != null) {
        if (lastMsgData is Map) {
          try {
            lastMessage = MessageModel.fromJson(
              Map<String, dynamic>.from(lastMsgData),
            );
          } catch (e) {
            lastMessage = null;
          }
        } else if (lastMsgData is String) {
          // If it's just an ID, we can't create a full message, so leave it null
          // The chat page will load messages separately
          lastMessage = null;
        }
      }
    } catch (e) {
      lastMessage = null;
    }

    // Handle unreadCount - API may have separate counts for organization and homeless
    int unreadCount =
        json['unreadCount'] ??
        json['unreadCountOrganization'] ??
        json['unreadCountHomeless'] ??
        0;

    return ChatModel(
      id: json['_id'] ?? json['id'] ?? '',
      organization: organization,
      homeless: homeless,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organization': organization?.toJson(),
      'homeless': homeless?.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class ChatUser {
  final String id;
  final String? name;
  final String? orgName;
  final String? fullName;
  final String? logo;
  final String? profilePicture;

  ChatUser({
    required this.id,
    this.name,
    this.orgName,
    this.fullName,
    this.logo,
    this.profilePicture,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    try {
      return ChatUser(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString(),
        orgName: json['orgName']?.toString(),
        fullName: json['fullName']?.toString(),
        logo: json['logo']?.toString(),
        profilePicture: json['profilePicture']?.toString(),
      );
    } catch (e) {
  
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'orgName': orgName,
      'fullName': fullName,
      'logo': logo,
      'profilePicture': profilePicture,
    };
  }

  String get displayName => orgName ?? fullName ?? name ?? 'Unknown';
  String? get avatarUrl => logo ?? profilePicture;

  /// Get full URL for avatar image
  String? getAvatarUrl() {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return null;

    try {
      // If already a full URL, return as is
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }

      // If relative path starting with /, prepend base URL
      if (url.startsWith('/')) {
        return '$baseUrl$url';
      }

      // If no leading slash, add it
      return '$baseUrl/$url';
    } catch (e) {
      return null;
    }
  }
}

class MessageModel {
  final String id;
  final MessageSender sender;
  final String text;
  final bool read;
  final DateTime createdAt;
  final String? chatId;

  MessageModel({
    required this.id,
    required this.sender,
    required this.text,
    this.read = false,
    required this.createdAt,
    this.chatId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle sender - could be a Map, List, or just an ID (String)
      MessageSender sender;
      final senderData = json['sender'];

      if (senderData is Map<String, dynamic>) {
        sender = MessageSender.fromJson(senderData);
      } else if (senderData is Map) {
        sender = MessageSender.fromJson(Map<String, dynamic>.from(senderData));
      } else if (senderData is String) {
        // If it's just an ID, create a minimal MessageSender
        sender = MessageSender(
          id: senderData,
          role: json['role']?.toString() ?? 'unknown',
          username: json['email']?.toString() ?? json['username']?.toString(),
        );
      } else if (senderData is List && senderData.isNotEmpty) {
        final firstItem = senderData[0];
        if (firstItem is Map) {
          sender = MessageSender.fromJson(Map<String, dynamic>.from(firstItem));
        } else {
          throw Exception('Invalid sender format: List with non-Map item');
        }
      } else {
        // Fallback: try to extract from other fields
        sender = MessageSender(
          id: (json['senderId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
          role: json['role']?.toString() ?? 'unknown',
          username: json['email']?.toString() ?? json['username']?.toString(),
        );
      }

      return MessageModel(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        sender: sender,
        text: json['text']?.toString() ?? '',
        read: json['read'] == true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        chatId: json['chatId']?.toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'text': text,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'chatId': chatId,
    };
  }
}

class MessageSender {
  final String id;
  final String? username;
  final String role;

  MessageSender({required this.id, this.username, required this.role});

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'],
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'username': username, 'role': role};
  }
}
