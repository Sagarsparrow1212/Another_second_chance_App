import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../widgets/custom_appbar.dart';
import '../../data/models/chat_model.dart';
import '../providers/chat_providers.dart';
import '../../../../common/auth/data/services/auth_storage_service.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  String? _userRole;
  IO.Socket? _socket;
  DateTime? _lastInvalidation;
  static const _invalidationDebounceMs = 500; // Debounce invalidations by 500ms

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    ref.read(allChatsProvider.future);
    _setupWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh chat list when page becomes visible (e.g., navigating back from chat)
    // This ensures the list shows the latest messages from cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Refresh to get latest data from cache
        ref.invalidate(allChatsProvider);

        // Re-establish socket listeners if socket is already connected
        // This is important because chat_page might have removed listeners on dispose
        final datasource = ref.read(chatRemoteDatasourceProvider);
        final socket = datasource.socket;
        if (socket != null && socket.connected) {
          // Always re-establish listeners when page becomes visible
          // This ensures listeners are active even if they were removed elsewhere
          if (_socket != socket) {
            _socket = socket;
          }
          _setupSocketListeners(socket);
        }
      }
    });
  }

  void _setupSocketListeners(IO.Socket socket) {
    if (!socket.connected) {
      return;
    }

    // Remove existing listeners first to avoid duplicates
    // This is safe because we'll immediately add them back
    socket.off('newMessage');
    socket.off('messagesRead');
    socket.off('messageRead');
    socket.off('connect');
    socket.off('error');

    // Listen for new messages to update chat list in real-time
    socket.on('newMessage', (data) {
      if (data is Map<String, dynamic> && mounted) {
        try {
          final messageChatId =
              data['chatId'] ??
              data['chat']?['_id'] ??
              data['chat']?['id'] ??
              data['chatId'];

          // CRITICAL: Update local cache immediately with the new message
          // This ensures the chat list shows the latest message even if getAllChats()
          // returns cached data
          final message = MessageModel.fromJson(data);
          // Ensure chatId is set
          final messageWithChatId = MessageModel(
            id: message.id,
            sender: message.sender,
            text: message.text,
            read: message.read,
            createdAt: message.createdAt,
            chatId: messageChatId ?? message.chatId,
          );

          // Update cache immediately (fire and forget)
          final localDatasource = ref.read(chatLocalDatasourceProvider);
          localDatasource
              .saveMessage(messageWithChatId)
              .then((_) async {
                // Update chat's last message in cache
                if (messageChatId != null) {
                  await localDatasource.updateChatLastMessage(
                    messageChatId,
                    messageWithChatId,
                  );
                }
                // Now invalidate to refresh UI
                _debouncedInvalidate();
              })
              .catchError((e) {
                // Still invalidate even if cache update fails
                _debouncedInvalidate();
              });
        } catch (e) {
          // Still invalidate to try to refresh
          _debouncedInvalidate();
        }
      } else {}
    });

    // Listen for real-time read status updates (messagesRead - plural)
    socket.on('messagesRead', (data) {
      if (data is Map<String, dynamic> && mounted) {
        _debouncedInvalidate();
      }
    });

    // Listen for individual message read updates (backward compatibility)
    socket.on('messageRead', (data) {
      if (data is Map<String, dynamic> && mounted) {
        _debouncedInvalidate();
      }
    });

    // Re-establish listeners on reconnect
    socket.on('connect', (_) {
      // Re-setup listeners on reconnect
      if (mounted) {
        _setupSocketListeners(socket);
      }
    });

    // Add error listener for debugging
    socket.on('error', (error) {});

    // Verify listeners are attached
  }

  void _setupWebSocket() {
    // Try to get socket directly first (might already be connected)
    final datasource = ref.read(chatRemoteDatasourceProvider);
    final existingSocket = datasource.socket;

    if (existingSocket != null && existingSocket.connected) {
      if (mounted) {
        setState(() {
          _socket = existingSocket;
        });
      }
      _setupSocketListeners(existingSocket);
      return;
    }

    // Otherwise, wait for connection provider and then set up
    ref
        .read(socketConnectionProvider.future)
        .then((_) {
          final datasource = ref.read(chatRemoteDatasourceProvider);

          // Check if socket is already connected
          final socket = datasource.socket;
          if (socket != null && socket.connected) {
            if (mounted) {
              setState(() {
                _socket = socket;
              });
            }
            _setupSocketListeners(socket);
          } else {
            // Connect socket
            datasource
                .connectSocket()
                .then((socket) {
                  if (mounted) {
                    setState(() {
                      _socket = socket;
                    });
                  }

                  // Set up socket listeners
                  _setupSocketListeners(socket);
                })
                .catchError((e) {
                  // Continue without WebSocket - app will still work
                });
          }
        })
        .catchError((e) {
          // Try to connect anyway
          final datasource = ref.read(chatRemoteDatasourceProvider);
          datasource
              .connectSocket()
              .then((socket) {
                if (mounted) {
                  setState(() {
                    _socket = socket;
                  });
                }
                _setupSocketListeners(socket);
              })
              .catchError((err) {});
        });
  }

  @override
  void dispose() {
    // NOTE: We DON'T remove socket listeners here because:
    // 1. The socket is shared across pages
    // 2. Other pages (like chat_page) might need these listeners
    // 3. The socket will be cleaned up when the app closes
    // If we remove listeners here, it breaks real-time updates
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthStorageService.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  void _debouncedInvalidate() {
    final now = DateTime.now();
    if (_lastInvalidation == null ||
        now.difference(_lastInvalidation!).inMilliseconds >
            _invalidationDebounceMs) {
      _lastInvalidation = now;
      Future.microtask(() {
        if (mounted) {
          ref.invalidate(allChatsProvider);
        }
      });
    }
  }

  ChatUser? _getChatPartner(ChatModel chat) {
    if (_userRole == 'organization') {
      return chat.homeless;
    } else if (_userRole == 'homeless') {
      return chat.organization;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Ensure socket listeners are ALWAYS active whenever widget builds
    // This is important because chat_page might have removed listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final datasource = ref.read(chatRemoteDatasourceProvider);
        final socket = datasource.socket;
        if (socket != null && socket.connected) {
          // Always re-establish listeners to ensure they're active
          // This handles the case where chat_page removed them
          if (_socket != socket) {
            _socket = socket;
          }
          // Always set up listeners - this ensures they're active even if removed elsewhere
          _setupSocketListeners(socket);
        } else if (socket == null || !socket.connected) {
          // Socket not connected, try to set it up
          _setupWebSocket();
        }
      }
    });

    final chatsAsync = ref.watch(allChatsProvider);

    return RefreshIndicator(
      edgeOffset: 100,
      onRefresh: () async {
        ref.invalidate(allChatsProvider);
      },
      child: Scaffold(
        drawer: AppDrawer(),
        appBar: CustomAppBar(title: 'Messages'),
        body: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 14, 9, 9),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final partner = _getChatPartner(chat);

                return InkWell(
                  onTap: () {
                    context.push('/chat/${chat.id}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: partner?.getAvatarUrl() != null
                              ? NetworkImage(partner!.getAvatarUrl()!)
                              : null,
                          child: partner?.getAvatarUrl() == null
                              ? Text(
                                  partner?.displayName[0].toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Chat info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      partner?.displayName ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (chat.updatedAt != null)
                                    Text(
                                      _formatTime(chat.updatedAt!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.lastMessage?.text ??
                                          'No messages yet',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (chat.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${chat.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Center(child: AppLoader()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading chats',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(allChatsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('pushing to start chat list page');
            context.push('/chat/start');
          },
          child: FaIcon(FontAwesomeIcons.plus),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
