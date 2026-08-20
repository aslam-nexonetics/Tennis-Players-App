import 'user.dart';

DateTime parseUtcDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  final String str = value.toString().trim();
  if (str.isEmpty) return DateTime.now();

  // If ISO string lacks timezone offset/Z (e.g. "2026-08-20T10:19:00"), treat as UTC
  if (!str.endsWith('Z') && !str.contains('+') && !RegExp(r'-\d{2}:?\d{2}$').hasMatch(str)) {
    final parsed = DateTime.tryParse('${str}Z');
    if (parsed != null) return parsed.toLocal();
  }
  final parsed = DateTime.tryParse(str);
  if (parsed != null) return parsed.toLocal();
  return DateTime.now();
}

class SearchedUserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;

  SearchedUserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
  });

  factory SearchedUserModel.fromJson(Map<String, dynamic> json) {
    return SearchedUserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
    );
  }
}

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime createdAt;
  final User? sender;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id']
          : int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.parse(json['sender_id'].toString()),
      content: json['content'] ?? '',
      createdAt: parseUtcDateTime(json['created_at']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    );
  }
}

class ConversationParticipantModel {
  final int id;
  final int userId;
  final User user;
  final DateTime joinedAt;
  final DateTime? lastReadAt;

  ConversationParticipantModel({
    required this.id,
    required this.userId,
    required this.user,
    required this.joinedAt,
    this.lastReadAt,
  });

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) {
    return ConversationParticipantModel(
      id: json['id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      joinedAt: parseUtcDateTime(json['joined_at']),
      lastReadAt: json['last_read_at'] != null
          ? parseUtcDateTime(json['last_read_at'])
          : null,
    );
  }
}

class ConversationModel {
  final int id;
  final bool isGroup;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipantModel> participants;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.isGroup,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
  });

  User? getOtherParticipant(int currentUserId) {
    try {
      return participants.firstWhere((p) => p.userId != currentUserId).user;
    } catch (_) {
      return null;
    }
  }

  String getDisplayName(int currentUserId) {
    if (isGroup && title != null && title!.isNotEmpty) {
      return title!;
    }
    final otherUser = getOtherParticipant(currentUserId);
    if (otherUser != null) {
      if (otherUser.fullName != null && otherUser.fullName!.isNotEmpty) {
        return otherUser.fullName!;
      }
      return otherUser.username;
    }
    return 'Chat';
  }

  ConversationModel copyWith({
    int? id,
    bool? isGroup,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationParticipantModel>? participants,
    ChatMessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      isGroup: json['is_group'] ?? false,
      title: json['title'],
      createdAt: parseUtcDateTime(json['created_at']),
      updatedAt: parseUtcDateTime(json['updated_at']),
      participants: (json['participants'] as List? ?? [])
          .map((p) => ConversationParticipantModel.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null
          ? ChatMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
