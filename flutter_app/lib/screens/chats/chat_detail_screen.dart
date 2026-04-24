import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _showEmojiPicker = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  static const List<String> _emojis = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆', '😉', '😊',
    '😋', '😎', '😍', '🥰', '😘', '😗', '😙', '😚', '🙂', '🤗',
    '🤩', '🤔', '🤨', '😐', '😑', '😶', '🙄', '😏', '😣', '😥',
    '😮', '🤐', '😯', '😪', '😫', '🥱', '😴', '😌', '😛', '😜',
    '😝', '🤤', '😒', '😓', '😔', '😕', '🙃', '🤑', '😲', '☹️',
  ];

  @override
  void initState() {
    super.initState();
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

  void _handleTyping(String value) {
    final chatProvider = context.read<ChatProvider>();
    if (!_isTyping) {
      _isTyping = true;
      chatProvider.sendTypingStatus(widget.chat.id, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        chatProvider.sendTypingStatus(widget.chat.id, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    _messageController.clear();

    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      chatProvider.sendTypingStatus(widget.chat.id, false);
    }

    await chatProvider.sendMessage(widget.chat.id, text);
    _scrollToBottom(animated: true);
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start < 0 ? text.length : selection.start,
      selection.end < 0 ? text.length : selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start < 0 ? text.length : selection.start) +
            emoji.length,
      ),
    );
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
        final isTyping = chatProvider.isTypingInChat(widget.chat.id);

        // Auto-scroll when new messages arrive
        if (messages.isNotEmpty) {
          _scrollToBottom(animated: true);
        }

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 28,
            title: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  if (otherUser != null)
                    AvatarWidget(
                      user: otherUser,
                      size: 38,
                      showOnlineIndicator: false,
                    )
                  else
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(Icons.group, color: Colors.white, size: 22),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (otherUser != null)
                          Text(
                            isTyping
                                ? 'typing...'
                                : otherUser.online
                                    ? 'online'
                                    : TimeUtils.formatLastSeen(
                                        otherUser.lastSeen),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'view_contact', child: Text('View contact')),
                  const PopupMenuItem(
                      value: 'media', child: Text('Media, links and docs')),
                  const PopupMenuItem(
                      value: 'search', child: Text('Search')),
                  const PopupMenuItem(
                      value: 'mute', child: Text('Mute notifications')),
                  const PopupMenuItem(
                      value: 'disappearing',
                      child: Text('Disappearing messages')),
                  const PopupMenuItem(
                      value: 'wallpaper', child: Text('Wallpaper')),
                  const PopupMenuItem(
                      value: 'report', child: Text('Report')),
                  const PopupMenuItem(value: 'block', child: Text('Block')),
                  const PopupMenuItem(
                      value: 'clear', child: Text('Clear chat')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages area
              Expanded(
                child: Container(
                  color: kChatBackground,
                  child: chatProvider.isLoading && messages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: kPrimary))
                      : messages.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.yellow.shade100.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Messages are end-to-end encrypted.\nNo one outside of this chat can read them.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: messages.length + (isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == messages.length && isTyping) {
                                  return _buildTypingIndicator();
                                }

                                final message = messages[index];
                                final isMe =
                                    message.sender.id == currentUserId;

                                // Date separator
                                bool showDateSeparator = false;
                                if (index == 0) {
                                  showDateSeparator = true;
                                } else {
                                  final prev = messages[index - 1];
                                  showDateSeparator = !TimeUtils.isSameDay(
                                    prev.createdAt,
                                    message.createdAt,
                                  );
                                }

                                return Column(
                                  children: [
                                    if (showDateSeparator)
                                      _buildDateSeparator(message.createdAt),
                                    MessageBubble(
                                      message: message,
                                      isMe: isMe,
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ),
              // Emoji picker
              if (_showEmojiPicker)
                Container(
                  height: 250,
                  color: Colors.white,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _emojis.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => _insertEmoji(_emojis[index]),
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            _emojis[index],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Input area
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Emoji button
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                          if (_showEmojiPicker) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                      // Text input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onChanged: _handleTyping,
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                              }
                            },
                          ),
                        ),
                      ),
                      // Attach button
                      IconButton(
                        icon: Icon(Icons.attach_file,
                            color: Colors.grey.shade600),
                        onPressed: () {},
                      ),
                      // Camera button
                      IconButton(
                        icon: Icon(Icons.camera_alt_outlined,
                            color: Colors.grey.shade600),
                        onPressed: () {},
                      ),
                      // Send / Mic button
                      ValueListenableBuilder(
                        valueListenable: _messageController,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: hasText ? _sendMessage : null,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                hasText ? Icons.send : Icons.mic,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          TimeUtils.formatDateSeparator(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, bottom: 4, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2)
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
