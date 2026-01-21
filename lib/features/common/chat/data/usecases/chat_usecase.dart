import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';

class ChatUseCase {
  final ChatRepository repository;

  ChatUseCase(this.repository);

  Future<List<ChatModel>> getAllChats() async {
    return await repository.getAllChats();
  }

  Future<ChatModel> getOrCreateChat(
    String organizationId,
    String homelessId,
  ) async {
    return await repository.getOrCreateChat(organizationId, homelessId);
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    return await repository.getMessages(chatId);
  }

  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    return await repository.getMessagesPaginated(
      chatId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  Future<List<MessageModel>> syncNewMessages(String chatId) async {
    return await repository.syncNewMessages(chatId);
  }

  Future<MessageModel> sendMessage(String chatId, String text) async {
    return await repository.sendMessage(chatId, text);
  }

  Future<void> markAsRead(String chatId) async {
    return await repository.markAsRead(chatId);
  }

  Future<void> connectSocket() async {
    return await repository.connectSocket();
  }

  void disconnectSocket() {
    repository.disconnectSocket();
  }

  void joinChat(String chatId) {
    repository.joinChat(chatId);
  }

  void leaveChat(String chatId) {
    repository.leaveChat(chatId);
  }
}
