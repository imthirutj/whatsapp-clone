import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../constants.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/time_utils.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTypingInternally = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isTypingInternally = _messageController.text.isNotEmpty;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.leaveChat(widget.chat.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.loadMessages(widget.chat.id);
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  void _handleTypingStatus(String value) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendTypingStatus(widget.chat.id, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      chatProvider.sendTypingStatus(widget.chat.id, false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    _messageController.clear();
    chatProvider.sendTypingStatus(widget.chat.id, false);
    await chatProvider.sendMessage(widget.chat.id, text);
    _scrollToBottom(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chatProvider, _) {
        if (auth.currentUser == null) return const SizedBox.shrink();

        final currentUserId = auth.currentUser!.id;
        final otherUser = widget.chat.otherUser(currentUserId);
        final displayName = widget.chat.displayName(currentUserId);
        final messages = chatProvider.getMessagesForChat(widget.chat.id);
        final isOtherTyping = chatProvider.isTypingInChat(widget.chat.id);

        return Scaffold(
          backgroundColor: const Color(0xFFEFEAE2), // Matches Image 2 creamy beige
          appBar: AppBar(
            backgroundColor: const Color(0xFFEFEAE2),
            elevation: 0,
            leadingWidth: 32,
            leading: IconButton(
              padding: const EdgeInsets.only(left: 8),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF006A4E)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 8,
            title: Row(
              children: [
                if (otherUser != null)
                  AvatarWidget(user: otherUser, size: 38)
                else
                  const CircleAvatar(radius: 19, child: Icon(Icons.group)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: kOnSurface,
                        ),
                      ),
                      Text(
                        isOtherTyping ? 'typing...' : (otherUser?.online ?? false) ? 'Active now' : 'Last seen today',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isOtherTyping || (otherUser?.online ?? false) ? const Color(0xFF006A4E) : kOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.videocam_outlined, color: Color(0xFF006A4E)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.call_outlined, color: Color(0xFF006A4E)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.more_vert, color: kOnSurfaceVariant), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: messages.length + 1, // +1 for the "Today" separator
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildDateSeparator(messages.isNotEmpty 
                        ? messages[0].createdAt 
                        : DateTime.now());
                    }
                    
                    final message = messages[index - 1];
                    final isMe = message.sender.id == currentUserId;
                    bool showTail = true;
                    if (index > 1) {
                      showTail = messages[index - 2].sender.id != message.sender.id;
                    }
                    return MessageBubble(message: message, isMe: isMe, showTail: showTail);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: kOnSurfaceVariant),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _handleTypingStatus,
                      style: GoogleFonts.inter(fontSize: 16),
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: GoogleFonts.inter(color: kOnSurfaceVariant, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: kOnSurfaceVariant),
                    onPressed: () {},
                  ),
                  if (!_isTypingInternally)
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: kOnSurfaceVariant),
                      onPressed: () {},
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF006A4E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isTypingInternally ? Icons.send : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          TimeUtils.formatDateSeparator(date),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF667781),
          ),
        ),
      ),
    );
  }
}
