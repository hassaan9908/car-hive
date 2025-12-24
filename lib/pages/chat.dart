import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../models/conversation_model.dart';
import 'chat_detail_page.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  /// Static method to get total unread count stream for use in navigation badges
  /// Returns Stream.value(0) if user is not authenticated to avoid Firestore errors
  static Stream<int> getTotalUnreadCountStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    try {
      return ChatService().getTotalUnreadCount();
    } catch (e) {
      print('Error getting unread count stream: $e');
      return Stream.value(0);
    }
  }

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: isDark ? const Color(0xFFf48c25) : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Please login to view your chats',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chats'),
            const SizedBox(width: 8),
            StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf48c25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? const Color(0xFFf48c25) : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFf48c25) : Colors.black,
        ),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDark ? const Color(0xFFf48c25) : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: isDark ? const Color(0xFFf48c25) : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation from a car listing',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId =
                  conversation.getOtherParticipantId(currentUser.uid);
              final unreadCount =
                  conversation.getUnreadCountForUser(currentUser.uid);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _chatService.getUserInfo(otherUserId),
                builder: (context, userSnapshot) {
                  // Handle loading state
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(strokeWidth: 2),
                      title: Text('Loading...'),
                    );
                  }

                  // Handle error state
                  if (userSnapshot.hasError) {
                    return ListTile(
                      title: Text(
                        'Error loading user',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    );
                  }

                  final userData = userSnapshot.data;
                  final displayName = userData?['displayName']?.toString() ?? 'Unknown User';
                  final userEmail = userData?['email']?.toString() ?? '';
                  final photoUrl = userData?['photoUrl']?.toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFf48c25),
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              displayName.isNotEmpty && displayName != 'Unknown User'
                                  ? displayName[0].toUpperCase()
                                  : userEmail.isNotEmpty
                                      ? userEmail[0].toUpperCase()
                                      : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                      onBackgroundImageError: photoUrl != null && photoUrl.isNotEmpty
                          ? (exception, stackTrace) {
                              // If image fails to load, show initials
                              // This is handled by the child widget
                              print('Error loading avatar image: $exception');
                            }
                          : null,
                    ),
                    title: Text(
                      displayName.isNotEmpty ? displayName : userEmail,
                      style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      conversation.lastMessage.isNotEmpty 
                          ? conversation.lastMessage 
                          : 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? (isDark
                                ? const Color(0xFFf48c25)
                                : Colors.black87)
                            : (isDark ? Colors.white60 : Colors.grey[600]),
                        fontWeight: unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? const Color(0xFFf48c25)
                                : (isDark ? Colors.white54 : Colors.grey[600]),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf48c25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                            conversationId: conversation.id,
                            otherUserId: otherUserId,
                            otherUserName: displayName.isNotEmpty
                                ? displayName
                                : userEmail,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

/// Widget to display unread message badge on navigation icons
/// Handles auth state changes to avoid Firestore errors during login
class ChatBadgeIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ChatBadgeIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
  });

  @override
  State<ChatBadgeIcon> createState() => _ChatBadgeIconState();
}

class _ChatBadgeIconState extends State<ChatBadgeIcon> {
  Stream<int>? _unreadStream;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid race conditions during auth
    _initializeStream();
  }

  void _initializeStream() {
    // Add a small delay to ensure auth state is settled
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          setState(() {
            _unreadStream = Chat.getTotalUnreadCountStream();
            _isInitialized = true;
          });
        } else {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized or no user, show plain icon
    if (!_isInitialized || FirebaseAuth.instance.currentUser == null) {
      return Icon(widget.icon, size: widget.size, color: widget.color);
    }

    return StreamBuilder<int>(
      stream: _unreadStream,
      builder: (context, snapshot) {
        // Handle errors gracefully
        if (snapshot.hasError) {
          return Icon(widget.icon, size: widget.size, color: widget.color);
        }

        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(widget.icon, size: widget.size, color: widget.color),
            if (count > 0)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
