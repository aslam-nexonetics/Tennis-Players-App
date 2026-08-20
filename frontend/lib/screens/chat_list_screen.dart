import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';
import 'user_search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  void _loadConversations() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (authProvider.isLoggedIn) {
      chatProvider.fetchConversations(authProvider, currentUserId: currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUserId = authProvider.user?.id ?? -1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Chats'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Find Users',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadConversations(),
        child: chatProvider.isLoadingConversations
            ? const Center(child: CircularProgressIndicator())
            : chatProvider.conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 80, color: Colors.indigo.shade200),
                          const SizedBox(height: 16),
                          const Text(
                            'No active conversations yet.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Search for sports enthusiasts or friends to start chatting!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('Search Users'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: chatProvider.conversations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conv = chatProvider.conversations[index];
                      final title = conv.getDisplayName(currentUserId);
                      final lastMsg = conv.lastMessage;
                      final unread = conv.unreadCount;

                      String timeStr = '';
                      if (lastMsg != null) {
                        final now = DateTime.now();
                        final msgTime = lastMsg.createdAt.toLocal();
                        if (now.day == msgTime.day &&
                            now.month == msgTime.month &&
                            now.year == msgTime.year) {
                          timeStr = DateFormat('hh:mm a').format(msgTime);
                        } else {
                          timeStr = DateFormat('MMM d').format(msgTime);
                        }
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          child: Text(
                            title.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unread > 0 ? Colors.indigo.shade700 : Colors.grey,
                                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMsg != null ? lastMsg.content : 'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(conversation: conv),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserSearchScreen()),
          );
        },
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('New Chat'),
      ),
    );
  }
}
