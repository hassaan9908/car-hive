import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';
import '../services/cloudinary_service.dart';
import '../models/chat_message_model.dart';

const Color _kOrange = Color(0xFFFF9900);
const Color _kBg = Color(0xFF0A0A0A);
const Color _kSurface = Color(0xFF1E1E1E);
const Color _kReceived = Color(0xFF232323);
const Color _kOnline = Color(0xFF4CAF50);

const List<String> _quickReplies = [
  'Still available?',
  'Can we meet?',
  'Send location',
  'Schedule viewing',
  "What's your best price?",
];

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? adId;
  final String? adTitle;
  final String? adPrice;
  final String? adImageUrl;
  final String? adStatus;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.adId,
    this.adTitle,
    this.adPrice,
    this.adImageUrl,
    this.adStatus,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSending = false;
  bool _isUploading = false;
  bool _isOnline = false;
  String? _lastSeenLabel;

  // Ad banner fields — seeded from constructor, then refreshed from Firestore
  String? _adTitle;
  String? _adPrice;
  String? _adImageUrl;
  String? _adStatus;

  @override
  void initState() {
    super.initState();
    _adTitle = widget.adTitle;
    _adPrice = widget.adPrice;
    _adImageUrl = widget.adImageUrl;
    _adStatus = widget.adStatus;
    _loadOtherUserPresence();
    _loadConversationAdInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserPresence() async {
    try {
      final data =
          await _chatService.getUserInfo(widget.otherUserId);
      if (!mounted) return;
      final online = data?['isOnline'] == true;
      final lastSeenTs = data?['lastSeen'];
      String? label;
      if (!online && lastSeenTs != null) {
        final dt = lastSeenTs is Timestamp
            ? lastSeenTs.toDate()
            : null;
        if (dt != null) label = 'Last seen ${_humanTime(dt)}';
      }
      setState(() {
        _isOnline = online;
        _lastSeenLabel = label;
      });
    } catch (_) {}
  }

  Future<void> _loadConversationAdInfo() async {
    if (_adTitle != null || widget.conversationId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
      if (!mounted || !doc.exists) return;
      final d = doc.data()!;
      setState(() {
        _adTitle = d['adTitle']?.toString();
        _adPrice = d['adPrice']?.toString();
        _adImageUrl = d['adImageUrl']?.toString();
        _adStatus = d['adStatus']?.toString();
      });
    } catch (_) {}
  }

  Future<void> _markRead() async {
    try {
      await _chatService
          .markMessagesAsRead(widget.conversationId);
    } catch (_) {}
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kOrange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: _kOrange),
              ),
              title: const Text('Photo from gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kOrange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: _kOrange),
              ),
              title: const Text('Take a photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);

      final cloudinary = CloudinaryService();
      String url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        url = await cloudinary.uploadImageBytes(imageBytes: bytes);
      } else {
        url = await cloudinary.uploadImage(imageFile: File(picked.path));
      }

      // Send the image URL as a message — prefixed so the bubble renders it
      await _chatService.sendMessage(widget.otherUserId, '[image]$url');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send image: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage([String? preset]) async {
    final text =
        (preset ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    if (preset == null) _messageController.clear();

    try {
      await _chatService.sendMessage(
          widget.otherUserId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar:
            AppBar(backgroundColor: _kBg, title: const Text('Chat')),
        body: const Center(
            child: Text('Please login',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_adTitle != null && _adTitle!.isNotEmpty)
            _buildCarBanner(),
          Expanded(child: _buildMessages(currentUser.uid)),
          _buildQuickReplies(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final statusText = _isOnline
        ? 'Online now'
        : (_lastSeenLabel ?? '');

    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kOrange),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.otherUserName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          if (statusText.isNotEmpty)
            Text(
              statusText,
              style: TextStyle(
                color: _isOnline
                    ? _kOnline
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.more_vert, color: _kOrange),
          onPressed: () =>
              _showConversationMenu(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.white12),
      ),
    );
  }

  // ── Car listing banner ───────────────────────────────────────────────────

  Widget _buildCarBanner() {
    final isSold =
        (_adStatus ?? '').toLowerCase() == 'sold';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(
            bottom:
                BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _adImageUrl != null &&
                    _adImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _adImageUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _carIconBox(),
                  )
                : _carIconBox(),
          ),
          const SizedBox(width: 12),
          // Title + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _adTitle ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_adPrice != null &&
                    _adPrice!.isNotEmpty)
                  Text(
                    'PKR $_adPrice',
                    style: const TextStyle(
                        color: _kOrange, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSold
                  ? Colors.red.withOpacity(0.15)
                  : _kOnline.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSold ? Colors.red : _kOnline,
                width: 0.5,
              ),
            ),
            child: Text(
              isSold ? 'Sold' : 'Available',
              style: TextStyle(
                color: isSold ? Colors.red : _kOnline,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carIconBox() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          const Icon(Icons.directions_car, color: _kOrange, size: 22),
    );
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  Widget _buildMessages(String currentUserId) {
    return StreamBuilder<List<ChatMessage>>(
      stream:
          _chatService.getMessagesStream(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: _kOrange));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading messages',
                  style:
                      TextStyle(color: Colors.grey[600])));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 56, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text('No messages yet',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text('Start the conversation!',
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13)),
              ],
            ),
          );
        }

        // Auto-scroll on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            try {
              _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent);
            } catch (_) {}
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMe = msg.senderId == currentUserId;
            final showDate =
                _shouldShowDate(messages, index);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDate)
                  _buildDateSeparator(msg.timestamp),
                GestureDetector(
                  onLongPress: () =>
                      _showDeleteDialog(msg),
                  child: _buildBubble(msg, isMe),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDate(List<ChatMessage> msgs, int i) {
    if (i == 0) return true;
    final a = msgs[i].timestamp;
    final b = msgs[i - 1].timestamp;
    return a.day != b.day ||
        a.month != b.month ||
        a.year != b.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Colors.white12)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _dateLabel(date),
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8),
            ),
          ),
          const Expanded(
              child: Divider(color: Colors.white12)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 3,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Align(
        alignment:
            isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isMe ? _kOrange : _kReceived,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  Radius.circular(isMe ? 18 : 4),
              bottomRight:
                  Radius.circular(isMe ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.message.startsWith('[image]'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: msg.message.substring(7),
                    width: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 220,
                      height: 140,
                      color: Colors.black26,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: _kOrange, strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 220,
                      height: 80,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey),
                    ),
                  ),
                )
              else
                Text(
                  msg.message,
                  style: TextStyle(
                    color: isMe ? Colors.black87 : Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _msgTime(msg.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.black45
                          : Colors.grey[600],
                      fontSize: 10.5,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    _buildTick(msg.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTick(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.done,
            size: 13, color: Colors.black38);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all,
            size: 13, color: Colors.black38);
      case MessageStatus.read:
        return const Icon(Icons.done_all,
            size: 13, color: Colors.white70);
    }
  }

  // ── Quick replies ─────────────────────────────────────────────────────────

  Widget _buildQuickReplies() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickReplies[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF333333),
                    width: 0.5),
              ),
              child: Text(
                _quickReplies[index],
                style: const TextStyle(
                    color: Colors.white, fontSize: 12.5),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment
            GestureDetector(
              onTap: _isUploading ? null : _showAttachmentMenu,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kSurface,
                  shape: BoxShape.circle,
                ),
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kOrange),
                      )
                    : const Icon(Icons.attach_file,
                        color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14),
                  filled: true,
                  fillColor: _kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _isSending ? null : () => _sendMessage(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _msgTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:$m $period';
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday =
        today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'TODAY';
    if (d == yesterday) return 'YESTERDAY';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _humanTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }

  // ── Menus ─────────────────────────────────────────────────────────────────

  void _showConversationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.block,
                  color: Colors.red),
              title: const Text('Block user',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined,
                  color: Colors.orange),
              title: const Text('Report',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(ChatMessage msg) async {
    final del = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete message',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Delete this message for everyone?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style:
                    TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (del == true) {
      try {
        await _chatService.deleteMessage(
            widget.conversationId, msg.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
