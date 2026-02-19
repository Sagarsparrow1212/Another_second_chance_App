import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_local_datasource.dart';
import '../models/chat_model.dart';
import 'chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;

  ChatRepositoryImpl(this.remoteDatasource, this.localDatasource);

  @override
  Future<List<ChatModel>> getAllChats() async {
    // Load from local first (instant display)
    final localChats = localDatasource.getChats();

    // If we have recent local data (within 30 seconds), return it
    final lastSync = localDatasource.getLastChatSync();
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inSeconds < 30 &&
        localChats.isNotEmpty) {
      // Fetch from server in background and update local
      remoteDatasource
          .getAllChats()
          .then((remoteChats) {
            localDatasource.saveChats(remoteChats);
          })
          .catchError((e) {});
      return localChats;
    }

    // Otherwise, fetch from server and cache
    try {
      final remoteChats = await remoteDatasource.getAllChats();
      await localDatasource.saveChats(remoteChats);
      return remoteChats;
    } catch (e) {
      // If remote fails, return local data if available
      if (localChats.isNotEmpty) {
        return localChats;
      }
      rethrow;
    }
  }

  @override
  Future<ChatModel> getOrCreateChat(
    String organizationId,
    String homelessId,
  ) async {
    final chat = await remoteDatasource.getOrCreateChat(
      organizationId,
      homelessId,
    );
    await localDatasource.updateChat(chat);
    return chat;
  }

  @override
  Future<ChatModel> getOrCreateMerchantChat(
    String merchantId,
    String homelessId,
  ) async {
    final chat = await remoteDatasource.getOrCreateMerchantChat(
      merchantId,
      homelessId,
    );
    await localDatasource.updateChat(chat);
    return chat;
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId) async {
    // Load from local first (instant display)
    final localMessages = localDatasource.getMessages(chatId);

    // Sync new messages in background (fire and forget)
    syncNewMessages(chatId)
        .then((_) {
          // Success - messages are already saved to local storage
        })
        .catchError((e) {});

    // Return local messages immediately
    return localMessages;
  }

  @override
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    // First check if we have older messages locally
    final localOlderMessages = localDatasource.getMessagesPaginated(
      chatId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );

    // If we have enough local messages, return them
    if (localOlderMessages.length >= limit) {
      return localOlderMessages;
    }

    // Otherwise, fetch from server
    try {
      final remoteMessages = await remoteDatasource.getOlderMessages(
        chatId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );

      // Save to local storage
      if (remoteMessages.isNotEmpty) {
        await localDatasource.saveMessages(chatId, remoteMessages);
      }

      return remoteMessages;
    } catch (e) {
      // If remote fails, return what we have locally
      if (localOlderMessages.isNotEmpty) {
        return localOlderMessages;
      }
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> syncNewMessages(String chatId) async {
    try {
      // Get the latest message timestamp from local storage
      final latestTimestamp = localDatasource.getLatestMessageTimestamp(chatId);

      List<MessageModel> newMessages;
      if (latestTimestamp != null) {
        // Fetch only new messages since last sync
        newMessages = await remoteDatasource.getNewMessages(
          chatId,
          latestTimestamp,
        );
      } else {
        // First time loading - fetch recent messages (last 50)
        newMessages = await remoteDatasource.getMessages(chatId, limit: 50);
      }

      // Save new messages to local storage
      if (newMessages.isNotEmpty) {
        await localDatasource.saveMessages(chatId, newMessages);
      }

      return newMessages;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String text) async {
    final message = await remoteDatasource.sendMessage(chatId, text);
    // Save to local storage immediately
    await localDatasource.saveMessage(message);
    // Update chat's last message in cache
    await localDatasource.updateChatLastMessage(chatId, message);
    return message;
  }

  @override
  Future<void> markAsRead(String chatId) async {
    return await remoteDatasource.markAsRead(chatId);
  }

  @override
  Future<void> connectSocket() async {
    await remoteDatasource.connectSocket();
  }

  @override
  void disconnectSocket() {
    remoteDatasource.disconnectSocket();
  }

  @override
  void joinChat(String chatId) {
    remoteDatasource.joinChat(chatId);
  }

  @override
  void leaveChat(String chatId) {
    remoteDatasource.leaveChat(chatId);
  }

  @override
  bool isInChatRoom(String chatId) {
    return remoteDatasource.isInChatRoom(chatId);
  }

  @override
  Set<String> getJoinedChatRooms() {
    return remoteDatasource.getJoinedChatRooms();
  }
}
