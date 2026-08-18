import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<SearchedUserModel> _searchResults = [];
  List<ChatMessageModel> _activeMessages = [];
  int? _activeConversationId;
  int? _currentUserId;
  String? _currentToken;

  bool _isLoadingConversations = false;
  bool _isSearching = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;

  // User-scoped app-wide socket
  WebSocketChannel? _userChannel;
  StreamSubscription? _userSubscription;

  // Room-scoped socket (optional fallback)
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  List<ConversationModel> get conversations => _conversations;
  List<SearchedUserModel> get searchResults => _searchResults;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  int? get activeConversationId => _activeConversationId;

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isSearching => _isSearching;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;

  int get totalUnreadCount {
    return _conversations.fold(0, (sum, item) => sum + item.unreadCount);
  }

  // 1. Search Users
  Future<void> searchUsers(String query, String token) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _chatService.searchUsers(query, token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // 2. Fetch Inbox / Conversations & Connect User Socket
  Future<void> fetchConversations(String token, {int? currentUserId}) async {
    _currentToken = token;
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations(token);
      // Connect app-wide socket for user
      initializeUserSocket(token, currentUserId: _currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // Connect App-Wide User WebSocket
  void initializeUserSocket(String token, {int? currentUserId}) {
    _currentToken = token;
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    // Don't reconnect if already connected
    if (_userChannel != null) return;

    try {
      _userChannel = _chatService.connectUserWebSocket(token);
      _userSubscription = _userChannel!.stream.listen(
        (data) {
          _handleIncomingUserWebSocketMessage(data);
        },
        onError: (err) {
          debugPrint('User WebSocket error: $err');
          _disconnectUserSocket();
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_currentToken != null && _userChannel == null) {
              initializeUserSocket(_currentToken!, currentUserId: _currentUserId);
            }
          });
        },
        onDone: () {
          debugPrint('User WebSocket closed.');
          _disconnectUserSocket();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize user websocket: $e');
    }
  }

  void _disconnectUserSocket() {
    _userSubscription?.cancel();
    _userChannel?.sink.close();
    _userSubscription = null;
    _userChannel = null;
  }

  // 3. Start or Open Direct Chat
  Future<ConversationModel?> openDirectChat(int targetUserId, String token, {int? currentUserId}) async {
    _errorMessage = null;
    try {
      final conv = await _chatService.getOrCreateDirectConversation(targetUserId, token);
      // Refresh conversations list in background
      fetchConversations(token, currentUserId: currentUserId);
      return conv;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // 4. Enter Conversation Room
  Future<void> enterConversationRoom(int conversationId, String token, {int? currentUserId}) async {
    _currentToken = token;
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    // Leave previous room socket if open
    leaveRoomSocketOnly();

    _activeConversationId = conversationId;
    _isLoadingMessages = true;
    _activeMessages = [];

    // Mark conversation unread count as 0 locally
    _markConversationReadLocally(conversationId);
    notifyListeners();

    try {
      // Ensure user socket is connected
      initializeUserSocket(token, currentUserId: _currentUserId);

      // Mark read via REST backend
      _chatService.markRead(conversationId, token);

      // Load initial message history
      _activeMessages = await _chatService.getMessages(conversationId, token);
      _isLoadingMessages = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void _markConversationReadLocally(int conversationId) {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      final conv = _conversations[convIndex];
      if (conv.unreadCount > 0) {
        _conversations[convIndex] = conv.copyWith(unreadCount: 0);
      }
    }
  }

  // Handle incoming real-time messages from User WebSocket
  void _handleIncomingUserWebSocketMessage(dynamic data) {
    try {
      final parsed = json.decode(data.toString());
      if (parsed['type'] == 'chat_message' && parsed['data'] != null) {
        final message = ChatMessageModel.fromJson(parsed['data']);
        final int conversationId = message.conversationId;

        // 1. If user is currently in this conversation room, append to active messages
        if (conversationId == _activeConversationId) {
          if (!_activeMessages.any((m) => m.id == message.id)) {
            _activeMessages.add(message);
          }
          if (_currentToken != null) {
            _chatService.markRead(conversationId, _currentToken!);
          }
        }

        // 2. Update conversation list item (last message, timestamp, unread count) & move to top
        final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (convIndex != -1) {
          final conv = _conversations[convIndex];
          final bool isFromOtherUser = _currentUserId != null ? message.senderId != _currentUserId : true;
          final bool isCurrentlyActiveRoom = _activeConversationId == conversationId;

          int newUnreadCount = conv.unreadCount;
          if (isCurrentlyActiveRoom) {
            newUnreadCount = 0;
          } else if (isFromOtherUser) {
            newUnreadCount += 1;
          }

          final updatedConv = conv.copyWith(
            lastMessage: message,
            updatedAt: message.createdAt,
            unreadCount: newUnreadCount,
          );

          // Re-order list: move updated conversation to top
          _conversations.removeAt(convIndex);
          _conversations.insert(0, updatedConv);
        } else {
          // If conversation isn't in local list yet, re-fetch conversations
          if (_currentToken != null) {
            _chatService.getConversations(_currentToken!).then((freshList) {
              _conversations = freshList;
              notifyListeners();
            }).catchError((_) {});
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing user websocket payload: $e');
    }
  }

  // Send message over WebSocket
  void sendMessage(String content) {
    final text = content.trim();
    if (text.isEmpty || _activeConversationId == null) {
      return;
    }

    if (_userChannel != null) {
      final payload = json.encode({
        'conversation_id': _activeConversationId,
        'content': text,
      });
      _userChannel!.sink.add(payload);
    } else if (_channel != null) {
      final payload = json.encode({
        'content': text,
      });
      _channel!.sink.add(payload);
    }
  }

  // Leave specific conversation room detail view
  void leaveConversationRoom() {
    leaveRoomSocketOnly();
    _activeConversationId = null;
    _activeMessages = [];
    notifyListeners();
  }

  void leaveRoomSocketOnly() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  @override
  void dispose() {
    _disconnectUserSocket();
    leaveRoomSocketOnly();
    super.dispose();
  }
}

