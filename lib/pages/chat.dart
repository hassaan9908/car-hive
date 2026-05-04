import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../models/conversation_model.dart';
import 'chat_detail_page.dart';

const Color _kOrange = Color(0xFFFF9900);
const Color _kBg = Color(0xFF0A0A0A);
const Color _kCard = Color(0xFF141414);
const Color _kSurface = Color(0xFF1E1E1E);

class Chat extends StatefulWidget {
  const Chat({super.key});

  static Stream<int> getTotalUnreadCountStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);
    try {
      return ChatService().getTotalUnreadCount();
    } catch (e) {
      return Stream.value(0);
    }
  }

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  List<Conversation> _conversations = [];
  StreamSubscription<List<Conversation>>? _convSub;
  bool _loaded = false;
  // otherUserId → lowercase display name, built as conversations arrive
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Keep conversations in state so tab badges update in real-time
    _convSub = _chatService.getConversationsStream().listen((list) {
      if (mounted) setState(() { _conversations = list; _loaded = true; });
      _prefetchNames(list);
    });
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _prefetchNames(List<Conversation> conversations) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    for (final c in conversations) {
      final otherId = c.getOtherParticipantId(currentUser.uid);
      if (_nameCache.containsKey(otherId)) continue;
      _chatService.getUserInfo(otherId).then((data) {
        if (!mounted || data == null) return;
        final name = (data['displayName']?.toString().isNotEmpty == true
                ? data['displayName'].toString()
                : data['username']?.toString()) ??
            '';
        if (name.isNotEmpty) {
          setState(() => _nameCache[otherId] = name.toLowerCase());
        }
      });
    }
  }

  // Unread count for a given filter category
  int _unreadFor(String filter, String currentUserId) {
    return _conversations.fold(0, (sum, c) {
      final u = c.getUnreadCountForUser(currentUserId);
      if (u == 0) return sum;
      if (filter == 'buying' && c.buyerId != currentUserId) return sum;
      if (filter == 'selling' && c.sellerId != currentUserId) return sum;
      return sum + u;
    });
  }

  List<Conversation> _applyFilter(
    List<Conversation> all,
    String currentUserId,
    String filter,
  ) {
    var result = all.where((c) {
      if (filter == 'buying') {
        return c.buyerId == currentUserId;
      } else if (filter == 'selling') {
        return c.sellerId == currentUserId;
      }
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final otherId = c.getOtherParticipantId(currentUserId);
        final name = _nameCache[otherId] ?? '';
        final adTitle = (c.adTitle ?? '').toLowerCase();
        final lastMsg = c.lastMessage.toLowerCase();
        return name.contains(_searchQuery) ||
            adTitle.contains(_searchQuery) ||
            lastMsg.contains(_searchQuery);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildUnauthenticated();
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(currentUser.uid),
          Expanded(
            child: !_loaded
                ? const Center(
                    child: CircularProgressIndicator(color: _kOrange))
                : TabBarView(
                    controller: _tabController,
                    children:
                        ['all', 'buying', 'selling'].map((filter) {
                      final filtered =
                          _applyFilter(_conversations, currentUser.uid, filter);
                      if (filtered.isEmpty) return _buildEmpty(filter);
                      return _buildList(filtered, currentUser.uid);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      centerTitle: true,
      title: StreamBuilder<int>(
        stream: _chatService.getTotalUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chats',
                style: TextStyle(
                    color: _kOrange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: const [],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.white12),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style:
            const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle:
              TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey[600], size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Colors.grey[600], size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: _kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTabBar(String currentUserId) {
    final allU = _unreadFor('all', currentUserId);
    final buyU = _unreadFor('buying', currentUserId);
    final selU = _unreadFor('selling', currentUserId);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _kOrange,
        indicatorWeight: 2.5,
        labelColor: _kOrange,
        unselectedLabelColor: Colors.grey,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal),
        tabs: [
          _tabLabel('All', allU),
          _tabLabel('Buying', buyU),
          _tabLabel('Selling', selU),
        ],
      ),
    );
  }

  Tab _tabLabel(String label, int unread) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unread > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
      List<Conversation> conversations, String currentUserId) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        color: Colors.white.withOpacity(0.06),
        indent: 80,
        endIndent: 0,
      ),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return _ConversationTile(
          key: ValueKey(conv.id),
          conversation: conv,
          otherUserId: conv.getOtherParticipantId(currentUserId),
          unreadCount: conv.getUnreadCountForUser(currentUserId),
          chatService: _chatService,
          currentUserId: currentUserId,
        );
      },
    );
  }

  Widget _buildEmpty(String filter) {
    final messages = {
      'all':
          'No conversations yet\nStart chatting from a car listing',
      'buying':
          'No buying conversations\nBrowse cars and tap "Chat"',
      'selling':
          'No selling conversations\nBuyers will reach out on your listings',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 56, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            messages[filter] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: Colors.grey[800]),
          const SizedBox(height: 12),
          Text('Error loading chats',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUnauthenticated() {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        centerTitle: true,
        title: const Text('Chats',
            style: TextStyle(
                color: _kOrange, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text('Please login to view your chats',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String otherUserId;
  final int unreadCount;
  final ChatService chatService;
  final String currentUserId;

  static const List<Color> _avatarColors = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFFFF9900),
    Color(0xFF795548),
    Color(0xFF0288D1),
  ];

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.otherUserId,
    required this.unreadCount,
    required this.chatService,
    required this.currentUserId,
  });

  Color _avatarColor(String name) {
    if (name.isEmpty) return _kOrange;
    return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: chatService.getUserInfo(otherUserId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final displayName = (data?['displayName']?.toString().isNotEmpty ==
                    true
                ? data!['displayName'].toString()
                : data?['username']?.toString()) ??
            'User';
        final photoUrl = data?['photoUrl']?.toString();
        final isOnline = data?['isOnline'] == true;
        final hasPhoto =
            photoUrl != null && photoUrl.isNotEmpty;
        final initial = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';
        final hasUnread = unreadCount > 0;
        final adTitle = conversation.adTitle;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.04),
            highlightColor: Colors.white.withOpacity(0.02),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  conversationId: conversation.id,
                  otherUserId: otherUserId,
                  otherUserName: displayName,
                  adId: conversation.adId,
                  adTitle: conversation.adTitle,
                  adPrice: conversation.adPrice,
                  adImageUrl: conversation.adImageUrl,
                  adStatus: conversation.adStatus,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar + online dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            _avatarColor(displayName),
                        backgroundImage: hasPhoto
                            ? CachedNetworkImageProvider(
                                photoUrl!)
                            : null,
                        child: !hasPhoto
                            ? Text(initial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _kBg, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name + listing tag + preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        if (adTitle != null &&
                            adTitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: _kOrange
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kOrange
                                      .withOpacity(0.35),
                                  width: 0.5),
                            ),
                            child: Text(
                              adTitle,
                              style: const TextStyle(
                                  color: _kOrange,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ] else
                          const SizedBox(height: 4),
                        Text(
                          conversation.lastMessage.isNotEmpty
                              ? conversation.lastMessage
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? _kOrange
                                : Colors.grey[500],
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timestamp + badge
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(
                            conversation.lastMessageTime),
                        style: TextStyle(
                          color: hasUnread
                              ? _kOrange
                              : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2),
                          constraints:
                              const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20),
                          decoration: BoxDecoration(
                            color: _kOrange,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99
                                ? '99+'
                                : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold),
                          ),
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
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:$m $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}

// ---------------------------------------------------------------------------
// Nav badge icon (unchanged API, refreshed styling)
// ---------------------------------------------------------------------------

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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        setState(() {
          _unreadStream = user != null
              ? Chat.getTotalUnreadCountStream()
              : null;
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized ||
        FirebaseAuth.instance.currentUser == null) {
      return Icon(widget.icon,
          size: widget.size, color: widget.color);
    }

    return StreamBuilder<int>(
      stream: _unreadStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Icon(widget.icon,
              size: widget.size, color: widget.color);
        }
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(widget.icon,
                size: widget.size, color: widget.color),
            if (count > 0)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(
                      minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
