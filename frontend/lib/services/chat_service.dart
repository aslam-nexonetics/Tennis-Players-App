import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_model.dart';
import 'auth_api_service.dart';

class ChatService {
  static String get baseUrl => AuthApiService.baseUrl;

  static String get wsBaseUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://');
    }
    return base.replaceFirst('http://', 'ws://');
  }

  // 1. Search active users
  Future<List<SearchedUserModel>> searchUsers(String query, String token) async {
    if (query.trim().isEmpty) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((jsonItem) => SearchedUserModel.fromJson(jsonItem)).toList();
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to search users.');
    }
  }

  // 2. Fetch conversations list
  Future<List<ConversationModel>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((jsonItem) => ConversationModel.fromJson(jsonItem)).toList();
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to fetch conversations.');
    }
  }

  // 3. Get or create direct conversation
  Future<ConversationModel> getOrCreateDirectConversation(int targetUserId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/conversations/direct/$targetUserId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ConversationModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to start chat.');
    }
  }

  // 4. Fetch conversation messages
  Future<List<ChatMessageModel>> getMessages(
    int conversationId,
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/messages?limit=$limit&offset=$offset'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((jsonItem) => ChatMessageModel.fromJson(jsonItem)).toList();
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to fetch messages.');
    }
  }

  // 5. Mark conversation read
  Future<void> markRead(int conversationId, String token) async {
    await http.post(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // 6. Connect to User WebSocket (App-Wide)
  WebSocketChannel connectUserWebSocket(String token) {
    final uri = Uri.parse('$wsBaseUrl/chat/ws?token=$token');
    return WebSocketChannel.connect(uri);
  }

  // 7. Connect to Room WebSocket
  WebSocketChannel connectWebSocket(int conversationId, String token) {
    final uri = Uri.parse('$wsBaseUrl/chat/ws/$conversationId?token=$token');
    return WebSocketChannel.connect(uri);
  }
}
