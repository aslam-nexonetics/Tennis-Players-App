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

  bool _isLoadingConversations = false;
  bool _isSearching = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;

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

  // 2. Fetch Inbox / Conversations
  Future<void> fetchConversations(String token) async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations(token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // 3. Start or Open Direct Chat
  Future<ConversationModel?> openDirectChat(int targetUserId, String token) async {
    _errorMessage = null;
    try {
      final conv = await _chatService.getOrCreateDirectConversation(targetUserId, token);
      // Refresh conversations list in background
      fetchConversations(token);
      return conv;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // 4. Connect WebSocket & Load Messages for Conversation Room
  Future<void> enterConversationRoom(int conversationId, String token) async {
    // Leave previous channel if any
    leaveConversationRoom();

    _activeConversationId = conversationId;
    _isLoadingMessages = true;
    _activeMessages = [];
    notifyListeners();

    try {
      // Mark read via REST
      _chatService.markRead(conversationId, token);

      // Load initial message history
      _activeMessages = await _chatService.getMessages(conversationId, token);
      _isLoadingMessages = false;
      notifyListeners();

      // Connect WebSocket
      _channel = _chatService.connectWebSocket(conversationId, token);
      _subscription = _channel!.stream.listen(
        (data) {
          _handleIncomingWebSocketMessage(data);
        },
        onError: (err) {
          debugPrint('WebSocket error: $err');
        },
        onDone: () {
          debugPrint('WebSocket closed.');
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void _handleIncomingWebSocketMessage(dynamic data) {
    try {
      final parsed = json.decode(data.toString());
      if (parsed['type'] == 'chat_message' && parsed['data'] != null) {
        final message = ChatMessageModel.fromJson(parsed['data']);
        
        // Append to active messages if matching room
        if (message.conversationId == _activeConversationId) {
          // Avoid duplicate messages
          if (!_activeMessages.any((m) => m.id == message.id)) {
            _activeMessages.add(message);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing websocket payload: $e');
    }
  }

  // Send message over WebSocket
  void sendMessage(String content) {
    if (content.trim().isEmpty || _channel == null || _activeConversationId == null) {
      return;
    }

    final payload = json.encode({
      'content': content.trim(),
    });
    _channel!.sink.add(payload);
  }

  // Disconnect WebSocket when leaving detail screen
  void leaveConversationRoom() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _activeConversationId = null;
    _activeMessages = [];
  }
}
