import '../models/chat_model.dart';

abstract class ChatRepository {
  Future<List<ChatModel>> getAllChats();
  Future<ChatModel> getOrCreateChat(String organizationId, String homelessId);
  Future<ChatModel> getOrCreateMerchantChat(
    String merchantId,
    String homelessId,
  );
  Future<List<MessageModel>> getMessages(String chatId);
  Future<List<MessageModel>> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  });
  Future<List<MessageModel>> syncNewMessages(String chatId);
  Future<MessageModel> sendMessage(String chatId, String text);
  Future<void> markAsRead(String chatId);
  Future<void> connectSocket();
  void disconnectSocket();
  void joinChat(String chatId);
  void leaveChat(String chatId);
  bool isInChatRoom(String chatId);
  Set<String> getJoinedChatRooms();
}
