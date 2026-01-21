import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/usecases/chat_usecase.dart';
import '../../data/models/chat_model.dart';

// Dio provider
final chatDioProvider = Provider((ref) => Dio());

// Local datasource provider (singleton)
final chatLocalDatasourceProvider = Provider((ref) {
  final datasource = ChatLocalDatasource();
  // Initialize on first access
  datasource.init();
  return datasource;
});

// Remote datasource provider
final chatRemoteDatasourceProvider = Provider(
  (ref) => ChatRemoteDatasource(ref.watch(chatDioProvider)),
);

// Repository provider
final chatRepositoryProvider = Provider(
  (ref) => ChatRepositoryImpl(
    ref.watch(chatRemoteDatasourceProvider),
    ref.watch(chatLocalDatasourceProvider),
  ),
);

// Usecase provider
final chatUseCaseProvider = Provider(
  (ref) => ChatUseCase(ref.watch(chatRepositoryProvider)),
);

// Socket connection provider - ensures socket is connected only once
// This provider will attempt to connect but won't block if it fails
final socketConnectionProvider = FutureProvider<void>((ref) async {
  try {
    final useCase = ref.watch(chatUseCaseProvider);
    // Connect socket only once, but don't throw if it fails
    await useCase.connectSocket();
  } catch (e) {
    // Log error but don't fail - allow app to work without WebSocket
    // Return void to indicate attempt was made, even if it failed
    return;
  }
});

// All chats provider
final allChatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  // Try to connect socket in background (non-blocking)
  // Don't await - let it connect in background while we fetch chats
  ref.watch(socketConnectionProvider.future).catchError((e) {
  });

  // Fetch chats immediately - don't wait for socket
  final useCase = ref.watch(chatUseCaseProvider);
  return await useCase.getAllChats();
});

// Messages provider (takes chatId as parameter)
final messagesProvider = FutureProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) async {
  final useCase = ref.watch(chatUseCaseProvider);
  return await useCase.getMessages(chatId);
});

// Chat provider (for getting or creating a chat)
final chatProvider = FutureProvider.family<ChatModel, Map<String, String>>((
  ref,
  params,
) async {
  final useCase = ref.watch(chatUseCaseProvider);
  return await useCase.getOrCreateChat(
    params['organizationId']!,
    params['homelessId']!,
  );
});
