import 'package:go_router/go_router.dart';
import '../pages/chat_list_page.dart';
import '../pages/chat_page.dart';
import '../pages/CreateNewChat.dart';

final chatRoutes = [
  GoRoute(
    path: '/chat/start',
    builder: (context, state) => const StartChatListPage(),
  ),
  GoRoute(path: '/chat', builder: (context, state) => const ChatListPage()),
  GoRoute(
    path: '/chat/:chatId',
    builder: (context, state) {
      final chatId = state.pathParameters['chatId']!;
      return ChatPage(chatId: chatId);
    },
  ),
];
