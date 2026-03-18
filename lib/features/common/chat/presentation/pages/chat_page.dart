import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' as foundation;

import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/chat_model.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/models/pending_message_model.dart';
import '../providers/chat_providers.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isLoadingOlder = false; // For pagination
  bool _hasMoreMessages = true; // Track if more messages available
  bool _hasLoadedMessages = false; // Track if messages have been loaded
  bool _isLoadingMessages = false; // Prevent multiple simultaneous loads
  bool _hasMarkedAsRead = false; // Track if we've marked as read
  bool _listenerSetupInProgress = false; // Prevent duplicate listener setup
  String? _currentUserId;
  String? _currentUserRole;
  IO.Socket? _socket;

  // Chat partner details (the other user in the conversation)
  String? _chatPartnerName;
  String? _chatPartnerPhotoUrl;

  // Save datasource reference to avoid using ref in dispose
  ChatRemoteDatasource? _datasource;

  // Typing indicator state
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _typingUsername;

  // Debounce timer for scroll listener
  Timer? _scrollDebounceTimer;

  // Connectivity state
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _setupSocket();
    _setupTypingIndicator();
    _setupScrollListener();
    _setupConnectivityListener();
    _checkInitialConnectivity();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load older messages when scrolling near the top
      // Add threshold check to prevent multiple rapid calls
      if (_scrollController.position.pixels < 200 &&
          !_isLoadingOlder &&
          _hasMoreMessages &&
          _messages.isNotEmpty) {
        // Debounce to prevent multiple rapid calls
        _scrollDebounceTimer?.cancel();
        _scrollDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted &&
              _scrollController.position.pixels < 200 &&
              !_isLoadingOlder &&
              _hasMoreMessages &&
              _messages.isNotEmpty) {
            _loadOlderMessages();
          }
        });
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    print('userajlksdjflkasjdflkasjdflkasjdflkasjdflkasjdflkajsdf');
    try {
      final userBox = await Hive.openBox('userBox');
      final userId = userBox.get('userId')?.toString();
      // get the current user role
      final role = userBox.get('role')?.toString();
      if (role == 'organization') {
        final organizationBox = await Hive.openBox('organizationBox');
        final organizationDetails = organizationBox.get('organizationDetails');
        if (organizationDetails != null) {
          setState(() {
            _currentUserRole = 'organization';
          });
        }
      } else if (role == 'homeless') {
        final homelessBox = await Hive.openBox('homelessBox');
        final homelessDetails = homelessBox.get('homelessDetails');
        if (homelessDetails != null) {
          setState(() {
            _currentUserRole = 'homeless';
          });
        }
      } else if (role == 'merchant') {
        final merchantBox = await Hive.openBox('merchantBox');
        final merchantDetails = merchantBox.get('merchantDetails');
        if (merchantDetails != null) {
          setState(() {
            _currentUserRole = 'merchant';
          });
        }
      }
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
        // Load chat partner details after we know the current user
        _loadChatPartnerDetails();
      }
    } catch (e) {}
  }

  /// Load the chat partner's details (the other user in the conversation)
  Future<void> _loadChatPartnerDetails() async {
    try {
      final localDatasource = ref.read(chatLocalDatasourceProvider);
      var chat = localDatasource.getChat(widget.chatId);
      print(chat == null);
      // If chat is not found locally, try to fetch all chats to update cache
      if (chat == null) {
        try {
          // Fetch from server
          await ref.read(chatUseCaseProvider).getAllChats();
          // Try to get from local again
          chat = localDatasource.getChat(widget.chatId);
        } catch (e) {
          // Ignore error, will stay as loading/null
        }
      }
      print(chat?.homeless?.displayName);
      if (chat == null) {
        return;
      }

      // Determine which user is the chat partner based on current user's role
      ChatUser? chatPartner;
      if (_currentUserRole == 'organization') {
        // Current user is organization, so partner is homeless
        chatPartner = chat.homeless;
      } else if (_currentUserRole == 'homeless') {
        // Current user is homeless, so partner is organization
        chatPartner = chat.organization;
      } else if (_currentUserRole == 'merchant') {
        // Current user is merchant, so partner is homeless
        chatPartner = chat.homeless;
      } else {
        // Fallback: if role not set yet, try to guess or show unknown
        // Or if we created the chat as a merchant, we are the organization
        if (_currentUserId == chat.organization?.id) {
          chatPartner = chat.homeless;
        } else if (_currentUserId == chat.homeless?.id) {
          chatPartner = chat.organization;
        }
      }

      if (chatPartner != null && mounted) {
        print(chatPartner.displayName);
        //  print(chatPartner.getAvatarUrl());
        setState(() {
          _chatPartnerName = chatPartner!.displayName;
          _chatPartnerPhotoUrl = chatPartner.getAvatarUrl();
        });
      }
    } catch (e) {}
  }

  void _setupSocket() async {
    final datasource = ref.read(chatRemoteDatasourceProvider);
    _datasource = datasource;

    try {
      // Connect socket and wait for connection
      final socket = await datasource.connectSocket();

      if (mounted) {
        setState(() {
          _socket = socket;
        });
      }

      // CRITICAL: Set up newMessage listener FIRST, before joining chat room
      // This ensures we don't miss any messages that arrive immediately after joining
      _setupNewMessageListener(socket);

      // CRITICAL: Join chat room - must be done after socket is connected
      if (socket.connected) {
        datasource.joinChat(widget.chatId);

        // Also manually add to joined rooms (in case backend doesn't send confirmation)
        // This ensures we can receive messages even if confirmation is delayed
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!datasource.isInChatRoom(widget.chatId)) {}
        });

        // Verify join status after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          final isJoined = datasource.isInChatRoom(widget.chatId);
          if (isJoined) {
          } else {}
        });

        // Listen for join confirmation (if backend sends it)
        socket.once('joinedChat', (data) {});

        // Also listen for any room join events
        socket.on('roomJoined', (data) {});

        socket.on('chatJoined', (data) {});
      } else {
        // Retry connection
        _retrySocketConnection();
        return;
      }

      // Listen for real-time read status updates (messagesRead - plural)
      // This event is emitted when all messages in a chat are marked as read
      socket.on('messagesRead', (data) {
        if (data is Map<String, dynamic> && mounted) {
          final readChatId = data['chatId'] ?? data['chat']?['_id'];
          final readBy = data['readBy'];
          final readAt = data['readAt'];

          // Only update if this is for the current chat
          if (readChatId == widget.chatId) {
            // Check if the messages were read by someone else (not by current user)
            // If read by current user, we don't need to update (we already know)
            if (readBy != _currentUserId) {
              // Check mounted before setState
              if (mounted) {
                setState(() {
                  // Mark all messages in this chat as read
                  _messages = _messages.map((msg) {
                    // Only mark messages sent by current user as read
                    // (messages sent by others don't need read status)
                    if (_isMyMessage(msg)) {
                      return MessageModel(
                        id: msg.id,
                        sender: msg.sender,
                        text: msg.text,
                        read: true, // Mark as read
                        createdAt: msg.createdAt,
                        chatId: msg.chatId,
                      );
                    }
                    return msg;
                  }).toList();
                });
              }
            } else {}
          }
        }
      });

      // Also listen for individual message read (backward compatibility)
      socket.on('messageRead', (data) {
        if (data is Map<String, dynamic> && mounted) {
          final readChatId = data['chatId'] ?? data['chat']?['_id'];
          if (readChatId == widget.chatId) {
            // Check mounted before setState
            if (mounted) {
              setState(() {
                final messageId = data['messageId'] ?? data['_id'];
                _messages = _messages.map((msg) {
                  if (msg.id == messageId) {
                    return MessageModel(
                      id: msg.id,
                      sender: msg.sender,
                      text: msg.text,
                      read: true,
                      createdAt: msg.createdAt,
                      chatId: msg.chatId,
                    );
                  }
                  return msg;
                }).toList();
              });
            }
          }
        }
      });

      // Listen for connection status - rejoin room on reconnect
      socket.off('connect');
      socket.on('connect', (_) {
        if (mounted && _datasource != null) {
          // CRITICAL: Set up listener FIRST, then join room
          _setupNewMessageListener(socket);
          _datasource!.joinChat(widget.chatId);
        }
      });

      socket.on('disconnect', (reason) {});

      socket.on('connect_error', (error) {});

      // Listen for typing events from other users
      // Remove any existing listener first to avoid duplicates
      socket.off('typing');
      socket.on('typing', (data) {
        if (data is Map<String, dynamic> && mounted) {
          final typingChatId =
              data['chatId'] ?? data['chat']?['_id'] ?? data['chatId'];
          final userId = data['userId']?.toString() ?? data['userId'];
          final username =
              data['username'] ??
              data['email'] ??
              data['fullName'] ??
              'Someone';
          final isTyping = data['isTyping'] ?? true;

          // Normalize IDs for comparison (handle both String and ObjectId formats)
          final normalizedTypingChatId = typingChatId?.toString();
          final normalizedCurrentChatId = widget.chatId.toString();
          final normalizedUserId = userId?.toString();
          final normalizedCurrentUserId = _currentUserId?.toString();

          // Only update if this is for the current chat
          final isForCurrentChat =
              normalizedTypingChatId == normalizedCurrentChatId;

          // Check if typing is from another user (not current user)
          final isFromOtherUser =
              normalizedUserId != null &&
              normalizedCurrentUserId != null &&
              normalizedUserId != normalizedCurrentUserId;

          if (isForCurrentChat && isFromOtherUser) {
            final wasTyping = _typingUsername != null;

            // Check mounted before setState
            if (mounted) {
              setState(() {
                if (isTyping) {
                  _typingUsername = username;
                } else {
                  _typingUsername = null;
                }
              });

              // Scroll to bottom when typing indicator appears (not when it disappears)
              if (isTyping && !wasTyping) {
                // Wait a bit for the UI to update, then scroll to show typing indicator
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) {
                    _scrollToBottomWithTyping();
                  }
                });
              }
            }
          } else {
            if (!isForCurrentChat) {}
            if (!isFromOtherUser) {}
          }
        } else {}
      });
    } catch (e) {}
  }

  /// Setup typing indicator - emit typing/stopTyping events
  void _setupTypingIndicator() {
    _messageController.addListener(_handleTextChange);
  }

  /// Set up the newMessage listener for the socket
  void _setupNewMessageListener(IO.Socket socket) {
    // CRITICAL: Do NOT remove existing listeners with socket.off('newMessage')
    // because ChatListPage also needs the newMessage listener
    // Socket.IO supports multiple listeners on the same event, so we can add ours
    // without removing others. However, we need to check if we already added a listener
    // to avoid duplicates. We'll use a flag or check if listener exists.

    // Check if we already have a listener by using a unique identifier
    // Since Socket.IO doesn't provide a way to check existing listeners,
    // we'll just add the listener. If it's called multiple times, we'll have
    // duplicate handlers, but our duplicate detection in the handler will prevent
    // duplicate messages in the UI.

    // Actually, the best approach is to NOT remove the listener at all
    // and rely on our duplicate detection logic in the handler
    // However, ChatListPage calls socket.off('newMessage') which removes ALL listeners,
    // so we need to re-establish our listener after ChatListPage sets up its listeners.

    // Prevent duplicate setup
    if (_listenerSetupInProgress) {
      return;
    }
    _listenerSetupInProgress = true;

    socket.on('newMessage', (data) {
      if (data is Map<String, dynamic>) {
        // Handle different response formats - try multiple possible keys
        final messageChatId =
            data['chatId'] ??
            data['chat']?['_id'] ??
            data['chat']?['id'] ??
            data['chat']?.toString() ??
            data['_id']?.toString();

        // Normalize both IDs to strings for comparison
        final normalizedMessageChatId = messageChatId?.toString();
        final normalizedCurrentChatId = widget.chatId.toString();

        // Accept message if it's for this chat OR if chatId is null (might be broadcast)
        // Use exact match after normalization to avoid false positives
        final isForThisChat =
            normalizedMessageChatId == normalizedCurrentChatId ||
            normalizedMessageChatId == null ||
            normalizedMessageChatId.isEmpty;

        if (isForThisChat) {
          try {
            final message = MessageModel.fromJson(data);
            // Ensure chatId is set
            final messageWithChatId = MessageModel(
              id: message.id,
              sender: message.sender,
              text: message.text,
              read: message.read,
              createdAt: message.createdAt,
              chatId: widget.chatId,
            );

            // Save to local storage and update chat cache (fire and forget)
            final localDatasource = ref.read(chatLocalDatasourceProvider);
            localDatasource
                .saveMessage(messageWithChatId)
                .then((_) async {
                  // Update chat's last message in cache
                  await localDatasource.updateChatLastMessage(
                    widget.chatId,
                    messageWithChatId,
                  );
                  // Invalidate chat list provider to refresh chat list
                  // Use microtask to ensure cache update is complete
                  Future.microtask(() {
                    if (mounted) {
                      ref.invalidate(allChatsProvider);
                    }
                  });
                })
                .catchError((e) {});

            if (mounted) {
              setState(() {
                // Avoid duplicates - check by ID, text, and timestamp
                final exists = _messages.any(
                  (msg) =>
                      msg.id == messageWithChatId.id ||
                      (msg.text == messageWithChatId.text &&
                          msg.sender.id == messageWithChatId.sender.id &&
                          (msg.createdAt
                                  .difference(messageWithChatId.createdAt)
                                  .inSeconds
                                  .abs() <
                              5)), // Within 5 seconds = likely duplicate
                );
                if (!exists) {
                  _messages.add(messageWithChatId);
                  // Sort messages by createdAt
                  _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                } else {}
              });

              // Scroll after setState completes and ListView is updated
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  _scrollToBottom();
                }
              });

              // Auto-mark as read if chat is open and we've already marked once
              if (_hasMarkedAsRead) {
                _markAsReadSilently();
              }
            }
          } catch (e, stackTrace) {}
        } else {}
      } else {}
    });

    _listenerSetupInProgress = false;
  }

  /// Handle text changes and emit typing status
  void _handleTextChange() {
    final text = _messageController.text;

    if (text.isNotEmpty && !_isTyping) {
      // User started typing
      _isTyping = true;
      _emitTyping();
    }

    // Reset typing timer - will stop typing after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping && mounted) {
        _isTyping = false;
        _emitStopTyping();
      }
    });
  }

  /// Emit typing event to server
  void _emitTyping() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {'chatId': widget.chatId});
    } else {}
  }

  /// Emit stopTyping event to server
  void _emitStopTyping() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('stopTyping', {'chatId': widget.chatId});
    } else {}
  }

  void _retrySocketConnection() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _setupSocket();
      }
    });
  }

  @override
  void dispose() {
    // Stop typing indicator when leaving
    if (_isTyping) {
      _emitStopTyping();
    }
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();

    // Leave chat room and clean up WebSocket listeners
    if (_socket != null && _socket!.connected && _datasource != null) {
      _datasource!.leaveChat(widget.chatId);
    }

    // Clean up WebSocket listeners
    // NOTE: We DON'T remove 'newMessage', 'messagesRead', 'messageRead' listeners
    // because chat_list_page needs them. These are shared listeners.
    // Only remove listeners specific to this chat page
    _socket?.off('typing'); // Typing indicator
    _socket?.off('stopTyping'); // Stop typing indicator
    _socket?.off('roomJoined');
    _socket?.off('chatJoined');
    _socket?.off('joinedChat');
    // Don't remove 'connect', 'disconnect', 'connect_error' as they might be needed elsewhere
    // The socket will handle cleanup when it's disposed

    // Clean up connectivity listener
    _connectivitySubscription?.cancel();

    // Clean up scroll debounce timer
    _scrollDebounceTimer?.cancel();

    super.dispose();
  }

  /// Setup connectivity listener to detect network changes
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        if (isOnline) {
          // Reconnect socket
          _reconnectSocket();
          // Retry pending messages
          _retryPendingMessages();
        } else {}
      }
    });
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  /// Reconnect socket when internet comes back
  Future<void> _reconnectSocket() async {
    try {
      if (_datasource != null) {
        final socket = await _datasource!.connectSocket();
        if (mounted) {
          setState(() {
            _socket = socket;
          });
        }
        // Rejoin chat room
        _datasource!.joinChat(widget.chatId);
      }
    } catch (e) {}
  }

  /// Retry sending pending messages when online
  Future<void> _retryPendingMessages() async {
    if (!_isOnline || _currentUserId == null) return;

    try {
      final localDatasource = ref.read(chatLocalDatasourceProvider);
      final pendingMessages = localDatasource.getPendingMessagesForChat(
        widget.chatId,
      );

      if (pendingMessages.isEmpty) return;

      final useCase = ref.read(chatUseCaseProvider);

      for (final pendingMsg in pendingMessages) {
        try {
          // Send the pending message
          final message = await useCase.sendMessage(
            pendingMsg.chatId,
            pendingMsg.text,
          );

          // Remove from pending queue
          await localDatasource.removePendingMessage(pendingMsg.tempId);

          // Replace pending message in UI with sent message
          if (mounted) {
            setState(() {
              // Remove pending message
              _messages.removeWhere((msg) => msg.id == pendingMsg.tempId);
              // Add sent message - check for duplicates
              final exists = _messages.any(
                (msg) =>
                    msg.id == message.id ||
                    (msg.text == message.text &&
                        msg.sender.id == message.sender.id &&
                        (msg.createdAt
                                .difference(message.createdAt)
                                .inSeconds
                                .abs() <
                            5)),
              );
              if (!exists) {
                _messages.add(message);
                _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }
            });

            // Scroll after update
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _scrollToBottom();
              }
            });
          }
        } catch (e) {
          // Keep it in queue for next retry
        }
      }

      // Refresh chat list
      if (mounted) {
        ref.invalidate(allChatsProvider);
      }
    } catch (e) {}
  }

  void _scrollToBottom() {
    // Use multiple attempts to ensure scroll happens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performScrollToBottom();
    });
  }

  void _performScrollToBottom() {
    if (!mounted || !_scrollController.hasClients) {
      // Retry if not ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _performScrollToBottom();
        }
      });
      return;
    }

    try {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        // Use jumpTo for immediate, reliable scroll
        _scrollController.jumpTo(maxScroll);

        // Also try animateTo after a tiny delay for smoothness (optional)
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _scrollController.hasClients) {
            final currentMaxScroll = _scrollController.position.maxScrollExtent;
            if (currentMaxScroll > 0 && currentMaxScroll != maxScroll) {
              // Max scroll changed (new message added), scroll again
              _scrollController.jumpTo(currentMaxScroll);
            }
          }
        });
      }
    } catch (e) {}
  }

  /// Scroll to first unread message, or to bottom if all messages are read
  void _scrollToUnreadOrBottom() {
    if (_messages.isEmpty || _currentUserId == null) {
      _scrollToBottom();
      return;
    }

    // Get chat to check unreadCount
    final localDatasource = ref.read(chatLocalDatasourceProvider);
    final chat = localDatasource.getChat(widget.chatId);
    final unreadCount = chat?.unreadCount ?? 0;

    // If no unread messages, scroll to bottom
    if (unreadCount == 0) {
      _scrollToBottom();
      return;
    }

    // Find the first unread message (from the other person)
    // Unread messages are typically from the other person, not the current user
    int? firstUnreadIndex;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      // Check if message is from the other person (not current user)
      if (message.sender.id != _currentUserId) {
        firstUnreadIndex = i;
        break;
      }
    }

    // If we found an unread message, scroll to it
    if (firstUnreadIndex != null) {
      final unreadIndex =
          firstUnreadIndex; // Store in local variable for null safety
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          // Calculate scroll position for the unread message
          // We need to estimate the position based on message index
          // For simplicity, scroll to show a bit before the first unread message
          final estimatedItemHeight = 80.0; // Approximate height per message
          final targetPosition = (unreadIndex * estimatedItemHeight).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );

          _scrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // Retry if controller not ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              final estimatedItemHeight = 80.0;
              final targetPosition = (unreadIndex * estimatedItemHeight).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              );
              _scrollController.jumpTo(targetPosition);
            }
          });
        }
      });
    } else {
      // If no unread message found, scroll to bottom
      _scrollToBottom();
    }
  }

  /// Scroll to bottom including typing indicator
  void _scrollToBottomWithTyping() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Use jumpTo for immediate scroll when typing appears
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  Future<void> _loadMessages() async {
    // Only load messages once - check both flags to prevent race conditions
    if (_hasLoadedMessages || _isLoadingMessages) {
      return;
    }

    // Set loading flag immediately to prevent multiple calls
    _isLoadingMessages = true;

    // Load from local storage first (instant display)
    final localDatasource = ref.read(chatLocalDatasourceProvider);
    final localMessages = localDatasource.getMessages(widget.chatId);

    if (localMessages.isNotEmpty) {
      // Show local messages immediately
      // Also load pending messages for this chat
      final pendingMessages = localDatasource.getPendingMessagesForChat(
        widget.chatId,
      );

      // Convert pending messages to MessageModel for display
      final pendingMessageModels = pendingMessages.map((pending) {
        return MessageModel(
          id: pending.tempId,
          sender: MessageSender(
            id: pending.senderId,
            role: 'user',
            username: null,
          ),
          text: pending.text,
          read: false,
          createdAt: pending.createdAt,
          chatId: pending.chatId,
        );
      }).toList();

      // Combine local messages with pending messages
      final allMessages = [...localMessages, ...pendingMessageModels];
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _messages = allMessages;
        _isLoading = false;
        _hasLoadedMessages = true;
        _isLoadingMessages = false; // Clear loading flag
      });

      // Scroll to first unread message, or bottom if all read
      // Use a small delay to ensure ListView is fully built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToUnreadOrBottom();
        }
      });

      // Mark as read
      if (!_hasMarkedAsRead) {
        await _markAsReadSilently();
        setState(() {
          _hasMarkedAsRead = true;
        });
      }
    } else {
      // No local messages, show loading
      setState(() {
        _isLoading = true;
      });
    }

    // Sync new messages from server in background
    // Only sync if we haven't already loaded messages from server
    try {
      final useCase = ref.read(chatUseCaseProvider);
      // getMessages already syncs new messages via syncNewMessages in the repository
      // But we need to be careful not to call it multiple times
      // The repository's getMessages calls syncNewMessages as fire-and-forget
      // So we only need to call it once

      final localMessagesFromSync = await useCase.getMessages(widget.chatId);

      // Reload from local to get synced messages
      final syncedMessages = localDatasource.getMessages(widget.chatId);

      // Also get pending messages
      final pendingMessages = localDatasource.getPendingMessagesForChat(
        widget.chatId,
      );

      // Convert pending messages to MessageModel
      final pendingMessageModels = pendingMessages.map((pending) {
        return MessageModel(
          id: pending.tempId,
          sender: MessageSender(
            id: pending.senderId,
            role: 'user',
            username: null,
          ),
          text: pending.text,
          read: false,
          createdAt: pending.createdAt,
          chatId: pending.chatId,
        );
      }).toList();

      // Combine and remove duplicates
      final allMessages = <MessageModel>[];
      final seenIds = <String>{};

      for (final msg in [...syncedMessages, ...pendingMessageModels]) {
        // Check by ID first
        if (!seenIds.contains(msg.id)) {
          // Also check for duplicates by text + sender + time
          final isDuplicate = allMessages.any(
            (existing) =>
                existing.id == msg.id ||
                (existing.text == msg.text &&
                    existing.sender.id == msg.sender.id &&
                    (existing.createdAt
                            .difference(msg.createdAt)
                            .inSeconds
                            .abs() <
                        5)),
          );

          if (!isDuplicate) {
            allMessages.add(msg);
            seenIds.add(msg.id);
          }
        }
      }

      // Sort by createdAt
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _messages = allMessages;
        _isLoading = false;
        _hasLoadedMessages = true;
        _isLoadingMessages = false; // Clear loading flag
      });

      // Scroll to first unread message, or bottom if all read
      // Only if we didn't already scroll (i.e., if there were no local messages)
      if (localMessages.isEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToUnreadOrBottom();
          }
        });
      }

      // Mark messages as read ONCE when chat is opened
      if (!_hasMarkedAsRead) {
        await _markAsReadSilently();
        setState(() {
          _hasMarkedAsRead = true;
        });
      }

      // Retry loading chat partner details if not loaded yet
      if (_chatPartnerName == null) {
        _loadChatPartnerDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMessages = false; // Clear loading flag on error
        });
        // If we have local messages, don't show error
        if (localMessages.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
        }
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingOlder || !_hasMoreMessages || _messages.isEmpty) {
      return;
    }

    // Set loading flag immediately to prevent multiple calls
    setState(() {
      _isLoadingOlder = true;
    });

    try {
      final useCase = ref.read(chatUseCaseProvider);
      final oldestMessageId = _messages.first.id;

      final olderMessages = await useCase.getMessagesPaginated(
        widget.chatId,
        limit: 50,
        beforeMessageId: oldestMessageId,
      );

      if (mounted) {
        setState(() {
          if (olderMessages.isEmpty) {
            _hasMoreMessages = false;
          } else {
            // Remove duplicates before inserting
            final existingIds = _messages.map((m) => m.id).toSet();
            final newMessages = olderMessages.where((msg) {
              // Check by ID
              if (existingIds.contains(msg.id)) {
                return false;
              }
              // Also check for duplicates by text + sender + time
              return !_messages.any(
                (existing) =>
                    existing.id == msg.id ||
                    (existing.text == msg.text &&
                        existing.sender.id == msg.sender.id &&
                        (existing.createdAt
                                .difference(msg.createdAt)
                                .inSeconds
                                .abs() <
                            5)),
              );
            }).toList();

            if (newMessages.isNotEmpty) {
              // Prepend older messages
              _messages.insertAll(0, newMessages);

              // Maintain scroll position
              final scrollPosition = _scrollController.position.pixels;
              final maxScroll = _scrollController.position.maxScrollExtent;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients && mounted) {
                  final newMaxScroll =
                      _scrollController.position.maxScrollExtent;
                  final scrollDelta = newMaxScroll - maxScroll;
                  _scrollController.jumpTo(scrollPosition + scrollDelta);
                }
              });
            } else {
              _hasMoreMessages = false;
            }
          }
          _isLoadingOlder = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
          // If error, assume no more messages
          _hasMoreMessages = false;
        });
      }
    }
  }

  Future<void> _markAsReadSilently() async {
    try {
      await ref.read(chatUseCaseProvider).markAsRead(widget.chatId);
    } catch (e) {
      // Don't show error to user for read status
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Stop typing indicator when sending message
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _emitStopTyping();
    }

    final messageText = text;
    _messageController.clear();

    // Check if offline
    if (!_isOnline) {
      // Save as pending message
      await _savePendingMessage(messageText);
      return;
    }

    try {
      final useCase = ref.read(chatUseCaseProvider);

      // Send message via API
      final message = await useCase.sendMessage(widget.chatId, messageText);

      // Message is already saved to local storage by repository
      // Chat cache is also updated by repository
      // Invalidate chat list provider to refresh chat list immediately
      // Use a small delay to ensure cache update is complete
      Future.microtask(() {
        if (mounted) {
          ref.invalidate(allChatsProvider);
        }
      });

      // Add message optimistically (it will also come via WebSocket)
      // But we add it now for better UX
      if (mounted) {
        setState(() {
          // Check if message already exists (might have come via WebSocket first)
          // Check by ID, text, and timestamp to avoid duplicates
          final exists = _messages.any(
            (msg) =>
                msg.id == message.id ||
                (msg.text == message.text &&
                    msg.sender.id == message.sender.id &&
                    (msg.createdAt
                            .difference(message.createdAt)
                            .inSeconds
                            .abs() <
                        5)), // Within 5 seconds = likely duplicate
          );
          if (!exists) {
            _messages.add(message);
            // Sort messages by createdAt
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          } else {}
        });

        // Scroll after setState completes and ListView is updated
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _scrollToBottom();
          }
        });

        // Refocus the text field after sending message
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _messageFocusNode.canRequestFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
        // Re-add text to controller on error
        _messageController.text = messageText;
        // Refocus the text field so user can retry
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _messageFocusNode.canRequestFocus) {
            _messageFocusNode.requestFocus();
          }
        });
      }
    }
  }

  /// Save message as pending when offline
  Future<void> _savePendingMessage(String text) async {
    if (_currentUserId == null) return;

    try {
      final localDatasource = ref.read(chatLocalDatasourceProvider);

      // Generate temporary ID
      final tempId =
          'pending_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      // Create pending message
      final pendingMessage = PendingMessageModel(
        tempId: tempId,
        chatId: widget.chatId,
        text: text,
        createdAt: DateTime.now(),
        senderId: _currentUserId!,
      );

      // Save to pending queue
      await localDatasource.savePendingMessage(pendingMessage);

      // Create a temporary message model for UI display
      final tempMessage = MessageModel(
        id: tempId,
        sender: MessageSender(
          id: _currentUserId!,
          role: 'user', // You might want to get actual role
          username: null,
        ),
        text: text,
        read: false,
        createdAt: DateTime.now(),
        chatId: widget.chatId,
      );

      // Add to UI as pending message
      if (mounted) {
        setState(() {
          _messages.add(tempMessage);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _scrollToBottom();
        });

        // Show offline indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message will be sent when connection is restored'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _messageController.text = text;
    }
  }

  bool _isMyMessage(MessageModel message) {
    return message.sender.id == _currentUserId;
  }

  /// Check if message is pending (has temp ID)
  bool _isPendingMessage(MessageModel message) {
    return message.id.startsWith('pending_');
  }

  /// Build read status icon (similar to WhatsApp)
  /// Shows different states: sent, delivered, read
  Widget _buildReadStatusIcon(bool isRead) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isRead
          ? Icon(
              Icons.done_all,
              key: const ValueKey('read'),
              size: 16,
              color: Colors.blueAccent,
            )
          : Icon(
              Icons.done_all,
              key: const ValueKey('delivered'),
              size: 16,
              color: Colors.white70,
            ),
    );
  }

  /// Build typing indicator widget
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated typing dots
            _TypingDots(),
            const SizedBox(width: 8),
            Text(
              '$_typingUsername is typing...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CRITICAL: Re-establish newMessage listener when page becomes visible
    // This is needed because ChatListPage might have removed it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _socket != null && _socket!.connected) {
        _setupNewMessageListener(_socket!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Load messages ONCE on first build - check all flags to prevent multiple calls
    if (!_hasLoadedMessages && !_isLoading && !_isLoadingMessages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check flags after post-frame callback (in case state changed)
        if (!_hasLoadedMessages &&
            !_isLoading &&
            !_isLoadingMessages &&
            mounted) {
          _loadMessages();
        }
      });
    }

    // CRITICAL: Ensure newMessage listener is always active
    // ChatListPage might remove it when it sets up its listeners in build(),
    // so we need to re-establish it after ChatListPage is done
    // Use a longer delay to ensure ChatListPage has finished setting up its listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _socket != null &&
          _socket!.connected &&
          !_listenerSetupInProgress) {
        // Use a delay to ensure ChatListPage has set up its listeners first
        // ChatListPage sets up listeners in its build() method, so we need to wait
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _socket != null && _socket!.connected) {
            _setupNewMessageListener(_socket!);
          }
        });
      }
    });

    return PopScope(
      canPop: !_showEmoji,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showEmoji) {
          setState(() {
            _showEmoji = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1A1A1A),
            ),
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE9ECEF),
                  backgroundImage: (_chatPartnerPhotoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(_chatPartnerPhotoUrl!)
                      : null,
                  child: !(_chatPartnerPhotoUrl?.isNotEmpty ?? false)
                      ? Text(
                          (_chatPartnerName?.isNotEmpty ?? false)
                              ? _chatPartnerName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C757D),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _chatPartnerName ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // IconButton(
            //   onPressed: () {},
            //   icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1A1A1A)),
            // ),
            // const SizedBox(width: 8),
          ],
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? Center(child: AppLoader())
                  : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount:
                          _messages.length +
                          (_typingUsername != null ? 1 : 0) +
                          (_isLoadingOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at top when loading older messages
                        if (index == 0 && _isLoadingOlder) {
                          return Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: AppLoader()),
                          );
                        }

                        // Adjust index if loading indicator is shown
                        final messageIndex = _isLoadingOlder
                            ? index - 1
                            : index;

                        // Show typing indicator as last item
                        if (messageIndex == _messages.length &&
                            _typingUsername != null) {
                          print(
                            '⌨️ 🎨 Building typing indicator for: $_typingUsername',
                          );
                          return _buildTypingIndicator();
                        }

                        final message = _messages[messageIndex];
                        final isMyMessage = _isMyMessage(message);
                        final bool isLastInGroup =
                            messageIndex == _messages.length - 1 ||
                            _isMyMessage(_messages[messageIndex + 1]) !=
                                isMyMessage;

                        return Align(
                          alignment: isMyMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              left: isMyMessage ? 60 : 16,
                              right: isMyMessage ? 16 : 60,
                              top: 4,
                              bottom: isLastInGroup ? 8 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? const Color(0xFF15306C)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(
                                  isMyMessage ? 20 : 4,
                                ),
                                bottomRight: Radius.circular(
                                  isMyMessage ? 4 : 20,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: isMyMessage
                                  ? null
                                  : Border.all(color: Colors.grey.shade100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMyMessage
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'hh:mm a',
                                        ).format(message.createdAt),
                                        style: TextStyle(
                                          color: isMyMessage
                                              ? Colors.white.withValues(
                                                  alpha: 0.6,
                                                )
                                              : Colors.grey.shade500,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isMyMessage) ...[
                                        const SizedBox(width: 4),
                                        _isPendingMessage(message)
                                            ? const Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: Colors.white60,
                                              )
                                            : _buildReadStatusIcon(
                                                message.read,
                                              ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Message input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              _messageFocusNode.unfocus();
                              setState(() {
                                _showEmoji = !_showEmoji;
                              });
                            },
                            icon: Icon(
                              _showEmoji
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              color: Colors.grey.shade400,
                              size: 22,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              focusNode: _messageFocusNode,
                              onTap: () {
                                if (_showEmoji) {
                                  setState(() {
                                    _showEmoji = false;
                                  });
                                }
                              },
                              textInputAction: TextInputAction.send,
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(
                                  color: Color(0xFFADB5BD),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 5,
                              minLines: 1,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF15306C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF15306C).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      // constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ),
                ],
              ),
            ),
            if (_showEmoji)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text =
                        _messageController.text + emoji.emoji;
                  },
                  config: Config(
                    height: 250,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: const Color(0xFFF8F9FB),
                      columns: 7,
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.2
                              : 1.0),
                    ),
                    categoryViewConfig: const CategoryViewConfig(
                      backgroundColor: Colors.white,
                      indicatorColor: Color(0xFF15306C),
                      iconColorSelected: Color(0xFF15306C),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots widget
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600.withValues(
                    alpha: 0.3 + (_animations[index].value * 0.7),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
