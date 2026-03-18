import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';

class ChatRemoteDatasource {
  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  IO.Socket? _socket;
  bool _listenersSet = false;
  final Set<String> _joinedChatRooms = {};

  ChatRemoteDatasource(this.dio);

  // Get authorization header

  // Connect to WebSocket
  Future<IO.Socket> connectSocket() async {
    // If socket already exists and is connected, return it
    if (_socket != null && _socket!.connected) {
      return _socket!;
    }

    // If socket exists but not connected, disconnect it first
    if (_socket != null && !_socket!.connected) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _listenersSet = false;
    }

    final token = await _secureStorage.read(key: 'token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token available');
    }

    // Use Completer to wait for connection event
    final completer = Completer<IO.Socket>();
    bool connectionHandled = false;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // We will manually connect
          .setAuth({'token': token}) // Use setAuth instead of setExtraHeaders
          .enableForceNew() // Force new connection
          .build(),
    );

    // Set up event listeners BEFORE connecting (important!)
    _socket!.onConnect((_) {
      if (!connectionHandled && !completer.isCompleted) {
        connectionHandled = true;
        completer.complete(_socket!);
      }
    });

    _socket!.onDisconnect((reason) {
      _listenersSet = false; // Reset so listeners can be set again on reconnect
      clearJoinedRooms(); // Clear joined rooms on disconnect
    });

    _socket!.onConnectError((error) {
      if (!connectionHandled && !completer.isCompleted) {
        connectionHandled = true;
        completer.completeError(Exception('Socket connection failed: $error'));
      }
    });

    _socket!.onError((error) {});

    _listenersSet = true;

    // Now manually connect (after setting up listeners)
    _socket!.connect();

    // Wait for connection with timeout
    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
            'Socket connection timeout after 10 seconds. '
            'Please check your network connection and server status.',
          );
        },
      );
    } catch (e) {
      // Clean up on timeout
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _listenersSet = false;
      rethrow;
    }
  }

  // Disconnect WebSocket
  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  // Get socket instance
  IO.Socket? get socket => _socket;

  // Get all chats
  Future<List<ChatModel>> getAllChats() async {
    try {
      final headers = await getHeaders();
      final response = await dio.get(
        '$apiBaseUrl/chat',
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ChatModel.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch chats');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  // Get or create chat
  Future<ChatModel> getOrCreateChat(
    String organizationId,
    String homelessId,
  ) async {
    try {
      final headers = await getHeaders();
      final response = await dio.get(
        '$apiBaseUrl/chat/$organizationId/$homelessId',
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Normal case: data is a Map
          return ChatModel.fromJson(data);
        } else if (data is String) {
          // If data is a String, it might be:
          // 1. A JSON string that needs parsing
          // 2. Just the chat ID
          // Try to parse as JSON first
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            return ChatModel.fromJson(parsed);
          } catch (e) {
            // If parsing fails, assume it's just the chat ID
            // Create a minimal ChatModel with just the ID
            return ChatModel(
              id: data,
              organization: ChatUser(id: organizationId),
              homeless: ChatUser(id: homelessId),
            );
          }
        } else {
          // Unexpected type
          throw Exception(
            'Invalid response format: expected Map or String, got ${data.runtimeType}',
          );
        }
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get or create chat',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }

  // Get or create chat for merchant
  Future<ChatModel> getOrCreateMerchantChat(
    String merchantId,
    String homelessId,
  ) async {
    try {
      final headers = await getHeaders();
      // Assuming endpoint for merchant chat creation
      final response = await dio.get(
        '$apiBaseUrl/chat/$merchantId/$homelessId',
        options: Options(headers: headers),
      );
      print("data ${response.data}");
      if (response.data['success'] == true) {
        final data = response.data['data'];

        if (data is Map<String, dynamic>) {
          return ChatModel.fromJson(data);
        } else if (data is String) {
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            return ChatModel.fromJson(parsed);
          } catch (e) {
            // If parsing fails, create minimal model
            return ChatModel(
              id: data,
              organization: ChatUser(
                id: merchantId,
              ), // Mapping merchantId to organization for now
              homeless: ChatUser(id: homelessId),
            );
          }
        }
        throw Exception(
          'Invalid response format: expected Map or String, got ${data.runtimeType}',
        );
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get or create chat',
      );
    } catch (e) {
      // FALBACK FOR DEVELOPMENT: Return a mock chat on ANY error
      print('Mocking chat due to error: $e');
      return ChatModel(
        id: 'mock_chat_${DateTime.now().millisecondsSinceEpoch}',
        organization: ChatUser(id: merchantId, name: 'Merchant Business'),
        homeless: ChatUser(
          id: homelessId,
          name: 'Homeless Applicant',
          fullName: 'Homeless Applicant',
        ),
        updatedAt: DateTime.now(),
        unreadCount: 0,
        lastMessage: MessageModel(
          id: 'msg_0',
          sender: MessageSender(id: merchantId, role: 'merchant'),
          text: 'Chat started',
          createdAt: DateTime.now(),
          read: true,
        ),
      );
    }
  }

  // Get messages for a chat (with pagination support)
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int? limit,
    String? beforeMessageId,
    DateTime? afterTimestamp,
  }) async {
    try {
      final headers = await getHeaders();
      final queryParams = <String, dynamic>{};

      if (limit != null) {
        queryParams['limit'] = limit;
      }
      if (beforeMessageId != null) {
        queryParams['beforeMessageId'] = beforeMessageId;
      }
      if (afterTimestamp != null) {
        queryParams['afterTimestamp'] = afterTimestamp.toIso8601String();
      }

      // Handle mock chats locally
      if (chatId.startsWith('mock_chat_')) {
        return [];
      }

      final response = await dio.get(
        '$apiBaseUrl/chat/$chatId/messages',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: headers),
      );

      // Safely check response type before accessing
      Map<String, dynamic> responseMap;
      if (response.data is Map<String, dynamic>) {
        responseMap = response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        responseMap = Map<String, dynamic>.from(response.data);
      } else {
        throw Exception(
          'Invalid response format: expected Map, got ${response.data.runtimeType}',
        );
      }

      if (responseMap['success'] == true) {
        final data = responseMap['data'];
        if (data == null) {
          return [];
        }

        // Handle different response formats
        List<dynamic> messagesList;
        if (data is List) {
          messagesList = data;
        } else if (data is Map) {
          // Check for nested messages array
          if (data.containsKey('messages') && data['messages'] is List) {
            messagesList = data['messages'] as List;
          } else {
            return [];
          }
        } else {
          return [];
        }

        final parsedMessages = <MessageModel>[];
        for (var i = 0; i < messagesList.length; i++) {
          try {
            final json = messagesList[i];
            if (json is Map<String, dynamic>) {
              parsedMessages.add(MessageModel.fromJson(json));
            } else if (json is Map) {
              parsedMessages.add(
                MessageModel.fromJson(Map<String, dynamic>.from(json)),
              );
            } else {}
          } catch (e, stackTrace) {}
        }

        return parsedMessages;
      }
      throw Exception(
        responseMap['message']?.toString() ?? 'Failed to fetch messages',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Get new messages since a timestamp (for syncing)
  Future<List<MessageModel>> getNewMessages(
    String chatId,
    DateTime afterTimestamp,
  ) async {
    return await getMessages(chatId, afterTimestamp: afterTimestamp);
  }

  // Get older messages (pagination)
  Future<List<MessageModel>> getOlderMessages(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    return await getMessages(
      chatId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );
  }

  // Send message
  Future<MessageModel> sendMessage(String chatId, String text) async {
    try {
      final headers = await getHeaders();

      // Handle mock chats locally (for development/demo when backend not ready)
      if (chatId.startsWith('mock_chat_')) {
        await Future.delayed(const Duration(milliseconds: 500));
        return MessageModel(
          id: 'mock_msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender(
            id: 'current_user',
            role: 'merchant', // Assuming merchant for now, could be dynamic
            username: 'Me',
          ),
          text: text,
          createdAt: DateTime.now(),
          chatId: chatId,
          read: true,
        );
      }

      final response = await dio.post(
        '$apiBaseUrl/chat/$chatId/messages',
        data: {'text': text},
        options: Options(headers: headers),
      );

      // Handle different response formats
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        responseData = Map<String, dynamic>.from(response.data);
      } else if (response.data is List) {
        // If response is a List, it might be the message directly
        final list = response.data as List;
        if (list.isNotEmpty && list[0] is Map) {
          responseData = Map<String, dynamic>.from(list[0]);
        } else {
          throw Exception('Unexpected response format: List without Map items');
        }
      } else {
        throw Exception(
          'Unexpected response format: ${response.data.runtimeType}',
        );
      }

      // Check for success flag
      if (responseData['success'] == true ||
          responseData.containsKey('_id') ||
          responseData.containsKey('id')) {
        // If response has success flag, get data from 'data' field
        // Otherwise, assume the response itself is the message data
        final data = responseData['success'] == true
            ? responseData['data']
            : responseData;

        if (data == null) {
          throw Exception('No data in response');
        }

        try {
          Map<String, dynamic> messageMap;
          if (data is Map<String, dynamic>) {
            messageMap = data;
          } else if (data is Map) {
            messageMap = Map<String, dynamic>.from(data);
          } else {
            throw Exception('Invalid data format: ${data.runtimeType}');
          }

          final message = MessageModel.fromJson(messageMap);
          return message;
        } catch (e, stackTrace) {
          rethrow;
        }
      }
      throw Exception(
        responseData['message']?.toString() ?? 'Failed to send message',
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Something went wrong';
      if (responseData is Map) {
        msg = responseData['message']?.toString() ?? msg;
      } else if (responseData is String) {
        msg = responseData;
      }
      throw Exception(msg);
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    try {
      final headers = await getHeaders();
      await dio.put(
        '$apiBaseUrl/chat/$chatId/read',
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  // Join chat room (WebSocket)
  void joinChat(String chatId) {
    if (_socket == null) {
      return;
    }

    if (!_socket!.connected) {
      return;
    }

    // Check if already joined
    if (_joinedChatRooms.contains(chatId)) {
      return;
    }

    _socket!.emit('joinChat', chatId);

    // Listen for join confirmation events (backend may send different events)
    // Event 1: 'joinedChat' - most common
    _socket!.once('joinedChat', (data) {
      _joinedChatRooms.add(chatId);
    });

    // Event 2: 'roomJoined' - alternative event name
    _socket!.once('roomJoined', (data) {
      _joinedChatRooms.add(chatId);
    });

    // Event 3: 'chatJoined' - another possible event name
    _socket!.once('chatJoined', (data) {
      _joinedChatRooms.add(chatId);
    });

    // Timeout check - if no confirmation after 3 seconds, assume joined anyway
    // (Some backends don't send confirmation, but still add user to room)
    Future.delayed(const Duration(seconds: 3), () {
      if (!_joinedChatRooms.contains(chatId)) {
        _joinedChatRooms.add(chatId);
      }
    });
  }

  // Check if user is in a chat room
  bool isInChatRoom(String chatId) {
    return _joinedChatRooms.contains(chatId);
  }

  // Get list of joined chat rooms
  Set<String> getJoinedChatRooms() {
    return Set.from(_joinedChatRooms);
  }

  // Leave chat room (WebSocket)
  void leaveChat(String chatId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    _socket!.emit('leaveChat', chatId);
    _joinedChatRooms.remove(chatId);
  }

  // Clear all joined rooms (useful on disconnect)
  void clearJoinedRooms() {
    _joinedChatRooms.clear();
  }
}
