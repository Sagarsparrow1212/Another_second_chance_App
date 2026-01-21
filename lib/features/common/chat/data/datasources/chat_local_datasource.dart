import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_model.dart';
import '../models/pending_message_model.dart';

class ChatLocalDatasource {
  static const String _messagesBoxName = 'messagesBox';
  static const String _chatsBoxName = 'chatsBox';
  static const String _chatMetadataBoxName = 'chatMetadataBox';
  static const String _pendingMessagesBoxName = 'pendingMessagesBox';

  // Box references (will be initialized in init)
  Box? _messagesBox;
  Box? _chatsBox;
  Box? _chatMetadataBox;
  Box? _pendingMessagesBox;

  /// Initialize Hive boxes
  Future<void> init() async {
    _messagesBox ??= await Hive.openBox(_messagesBoxName);
    _chatsBox ??= await Hive.openBox(_chatsBoxName);
    _chatMetadataBox ??= await Hive.openBox(_chatMetadataBoxName);
    _pendingMessagesBox ??= await Hive.openBox(_pendingMessagesBoxName);
  }

  // ==================== MESSAGES ====================

  /// Save a single message to local storage
  Future<void> saveMessage(MessageModel message) async {
    await init();
    final chatId = message.chatId ?? 'unknown';
    final messagesKey = 'messages_$chatId';

    // Get existing messages for this chat
    final existingMessages = getMessages(chatId);

    // Check if message already exists (avoid duplicates)
    if (existingMessages.any((m) => m.id == message.id)) {
      // Update existing message
      final updatedMessages = existingMessages.map((m) {
        return m.id == message.id ? message : m;
      }).toList();
      await _messagesBox!.put(messagesKey, _serializeMessages(updatedMessages));
    } else {
      // Add new message
      existingMessages.add(message);
      // Sort by createdAt (oldest first)
      existingMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      await _messagesBox!.put(
        messagesKey,
        _serializeMessages(existingMessages),
      );
    }
  }

  /// Save multiple messages to local storage
  Future<void> saveMessages(String chatId, List<MessageModel> messages) async {
    await init();
    final messagesKey = 'messages_$chatId';

    // Get existing messages
    final existingMessages = getMessages(chatId);
    final existingIds = existingMessages.map((m) => m.id).toSet();

    // Merge: add new messages, update existing ones
    for (final message in messages) {
      if (existingIds.contains(message.id)) {
        // Update existing
        final index = existingMessages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          existingMessages[index] = message;
        }
      } else {
        // Add new
        existingMessages.add(message);
      }
    }

    // Sort by createdAt (oldest first)
    existingMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await _messagesBox!.put(messagesKey, _serializeMessages(existingMessages));
  }

  /// Get all messages for a chat from local storage
  List<MessageModel> getMessages(String chatId) {
    if (_messagesBox == null) return [];

    final messagesKey = 'messages_$chatId';
    final data = _messagesBox!.get(messagesKey);

    if (data == null) return [];

    try {
      return _deserializeMessages(data);
    } catch (e) {
      return [];
    }
  }

  /// Get paginated messages (for loading older messages)
  List<MessageModel> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) {
    final allMessages = getMessages(chatId);

    if (allMessages.isEmpty) return [];

    // If beforeMessageId is provided, find messages before that message
    if (beforeMessageId != null) {
      final beforeIndex = allMessages.indexWhere(
        (m) => m.id == beforeMessageId,
      );
      if (beforeIndex == -1) return [];

      // Get messages before this index (older messages)
      final startIndex = (beforeIndex - limit).clamp(0, beforeIndex);
      return allMessages.sublist(startIndex, beforeIndex);
    }

    // Otherwise, return the last N messages (newest)
    final startIndex = (allMessages.length - limit).clamp(
      0,
      allMessages.length,
    );
    return allMessages.sublist(startIndex);
  }

  /// Get the latest message timestamp for a chat (for syncing)
  DateTime? getLatestMessageTimestamp(String chatId) {
    final messages = getMessages(chatId);
    if (messages.isEmpty) return null;
    return messages.last.createdAt;
  }

  /// Get the oldest message timestamp for a chat (for pagination)
  DateTime? getOldestMessageTimestamp(String chatId) {
    final messages = getMessages(chatId);
    if (messages.isEmpty) return null;
    return messages.first.createdAt;
  }

  /// Clear all messages for a chat
  Future<void> clearMessages(String chatId) async {
    await init();
    final messagesKey = 'messages_$chatId';
    await _messagesBox!.delete(messagesKey);
  }

  /// Clear all messages (for logout/cleanup)
  Future<void> clearAllMessages() async {
    await init();
    await _messagesBox!.clear();
  }

  // ==================== CHATS ====================

  /// Save chat list to local storage
  Future<void> saveChats(List<ChatModel> chats) async {
    await init();
    await _chatsBox!.put('allChats', _serializeChats(chats));
    // Also update last sync time
    await _chatMetadataBox!.put(
      'lastChatSync',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get chat list from local storage
  List<ChatModel> getChats() {
    if (_chatsBox == null) return [];

    final data = _chatsBox!.get('allChats');
    if (data == null) return [];

    try {
      return _deserializeChats(data);
    } catch (e) {
      return [];
    }
  }

  /// Get a single chat by ID
  ChatModel? getChat(String chatId) {
    final chats = getChats();
    try {
      return chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  /// Update a single chat (e.g., when new message arrives)
  Future<void> updateChat(ChatModel chat) async {
    await init();
    final chats = getChats();
    final index = chats.indexWhere((c) => c.id == chat.id);

    if (index != -1) {
      chats[index] = chat;
    } else {
      chats.add(chat);
    }

    // Sort by updatedAt (newest first)
    chats.sort((a, b) {
      final aTime = a.updatedAt ?? DateTime(1970);
      final bTime = b.updatedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    await _chatsBox!.put('allChats', _serializeChats(chats));
  }

  /// Update chat's last message (optimized update for new messages)
  Future<void> updateChatLastMessage(
    String chatId,
    MessageModel message,
  ) async {
    await init();
    final chats = getChats();
    final chatIndex = chats.indexWhere((c) => c.id == chatId);

    if (chatIndex != -1) {
      // Update existing chat
      final existingChat = chats[chatIndex];
      final updatedChat = ChatModel(
        id: existingChat.id,
        organization: existingChat.organization,
        homeless: existingChat.homeless,
        lastMessage: message,
        unreadCount: existingChat.unreadCount,
        updatedAt: message.createdAt,
      );
      chats[chatIndex] = updatedChat;

      // Sort by updatedAt (newest first)
      chats.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime(1970);
        final bTime = b.updatedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      await _chatsBox!.put('allChats', _serializeChats(chats));
    }
  }

  /// Clear all chats
  Future<void> clearChats() async {
    await init();
    await _chatsBox!.clear();
    await _chatMetadataBox!.clear();
  }

  /// Get last sync time for chats
  DateTime? getLastChatSync() {
    if (_chatMetadataBox == null) return null;
    final syncTime = _chatMetadataBox!.get('lastChatSync');
    if (syncTime == null) return null;
    try {
      return DateTime.parse(syncTime);
    } catch (e) {
      return null;
    }
  }

  // ==================== SERIALIZATION ====================

  /// Serialize messages to JSON string
  String _serializeMessages(List<MessageModel> messages) {
    final jsonList = messages.map((m) => m.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Deserialize messages from stored data
  List<MessageModel> _deserializeMessages(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data) as List;
        return decoded
            .map(
              (json) => MessageModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      } else if (data is List) {
        return data
            .map(
              (json) => MessageModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }
    } catch (e) {}
    return [];
  }

  /// Serialize chats to JSON
  String _serializeChats(List<ChatModel> chats) {
    final jsonList = chats.map((c) => c.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Deserialize chats from stored data
  List<ChatModel> _deserializeChats(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data) as List;
        return decoded
            .map(
              (json) => ChatModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      } else if (data is List) {
        return data
            .map(
              (json) => ChatModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }
    } catch (e) {}
    return [];
  }

  // ==================== PENDING MESSAGES ====================

  /// Save a pending message (message waiting to be sent)
  Future<void> savePendingMessage(PendingMessageModel message) async {
    await init();
    final pendingKey = 'pending_${message.tempId}';
    await _pendingMessagesBox!.put(pendingKey, jsonEncode(message.toJson()));
  }

  /// Get all pending messages
  List<PendingMessageModel> getPendingMessages() {
    if (_pendingMessagesBox == null) return [];

    final allKeys = _pendingMessagesBox!.keys
        .where((key) => key.toString().startsWith('pending_'))
        .toList();

    final pendingMessages = <PendingMessageModel>[];
    for (final key in allKeys) {
      try {
        final data = _pendingMessagesBox!.get(key);
        if (data != null) {
          final json = jsonDecode(data.toString()) as Map<String, dynamic>;
          pendingMessages.add(PendingMessageModel.fromJson(json));
        }
      } catch (e) {}
    }

    // Sort by createdAt (oldest first)
    pendingMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pendingMessages;
  }

  /// Get pending messages for a specific chat
  List<PendingMessageModel> getPendingMessagesForChat(String chatId) {
    return getPendingMessages().where((msg) => msg.chatId == chatId).toList();
  }

  /// Remove a pending message (after successful send)
  Future<void> removePendingMessage(String tempId) async {
    await init();
    final pendingKey = 'pending_$tempId';
    await _pendingMessagesBox!.delete(pendingKey);
  }

  /// Clear all pending messages
  Future<void> clearPendingMessages() async {
    await init();
    final allKeys = _pendingMessagesBox!.keys
        .where((key) => key.toString().startsWith('pending_'))
        .toList();
    for (final key in allKeys) {
      await _pendingMessagesBox!.delete(key);
    }
  }
}
