import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show FileUploadInputElement, FileReader;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:flutter/foundation.dart' as foundation;
import 'package:file_picker/file_picker.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';
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
  final _focusNode = FocusNode();
  bool _isTypingInternally = false;
  bool _showEmojiPicker = false;
  bool _isUploadingMedia = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isTypingInternally = _messageController.text.isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.clearActiveChat();
    chatProvider.leaveChat(widget.chat.id);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = context.read<ChatProvider>();
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    chatProvider.setActiveChat(widget.chat.id);
    await chatProvider.loadMessages(widget.chat.id);
    await chatProvider.markChatAsRead(widget.chat.id, currentUserId);
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
    chatProvider.sendLiveTypingText(widget.chat.id, value);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      chatProvider.sendTypingStatus(widget.chat.id, false);
      chatProvider.sendLiveTypingText(widget.chat.id, '');
    });
  }

  Future<void> _pickAndSendImage() async {
    if (foundation.kIsWeb) {
      await _pickAndSendImageWeb();
    } else {
      await _pickAndSendImageNative();
    }
  }

  // Web: use dart:html directly — no plugin registration needed
  Future<void> _pickAndSendImageWeb() async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) { completer.complete(null); return; }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0]);
      reader.onLoad.listen((_) {
        final result = reader.result;
        if (result is List<int>) {
          completer.complete(Uint8List.fromList(result));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) => completer.complete(null));
    });

    final bytes = await completer.future;
    if (bytes == null || !mounted) return;

    await _uploadAndSend(bytes, 'image.jpg');
  }

  // Native (mobile/desktop): use file_picker
  Future<void> _pickAndSendImageNative() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      final name = result.files.first.name;
      if (bytes == null) return;
      await _uploadAndSend(bytes, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadAndSend(Uint8List bytes, String filename) async {
    final chatProvider = context.read<ChatProvider>();
    final currentUser = context.read<AuthProvider>().currentUser!;
    setState(() => _isUploadingMedia = true);
    try {
      final mediaId = await ApiService().uploadMedia(bytes, filename, 'image/jpeg');
      await chatProvider.sendMessage(widget.chat.id, mediaId, currentUser, type: 'image');
      _scrollToBottom(animated: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    final currentUser = context.read<AuthProvider>().currentUser!;
    _messageController.clear();
    chatProvider.sendTypingStatus(widget.chat.id, false);
    chatProvider.sendLiveTypingText(widget.chat.id, '');
    await chatProvider.sendMessage(widget.chat.id, text, currentUser);
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
        final liveTypingText = chatProvider.getLiveTypingText(widget.chat.id);
        if (liveTypingText.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEFEAE2), // Matches Image 2 creamy beige
          appBar: AppBar(
            backgroundColor: const Color(0xFFEFEAE2),
            elevation: 0,
            leadingWidth: 40,
            leading: IconButton(
              padding: const EdgeInsets.only(left: 4),
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF006A4E)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                if (otherUser != null)
                  AvatarWidget(user: otherUser, size: 42, showOnlineIndicator: true)
                else
                  const CircleAvatar(radius: 21, child: Icon(Icons.group)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isOtherTyping
                            ? 'typing...'
                            : (otherUser?.online ?? false)
                                ? 'Active now'
                                : 'Last seen recently',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isOtherTyping || (otherUser?.online ?? false)
                              ? const Color(0xFF006A4E)
                              : kOnSurfaceVariant,
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
                child: GestureDetector(
                  onTap: () {
                    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: messages.length + 1 + (liveTypingText.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildDateSeparator(messages.isNotEmpty
                          ? messages[0].createdAt
                          : DateTime.now());
                      }

                      if (liveTypingText.isNotEmpty && index == messages.length + 1) {
                        return _buildLiveTypingBubble(liveTypingText);
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
              ),
              _buildInputArea(),
              if (_showEmojiPicker)
                SizedBox(
                  height: 280,
                  child: ep.EmojiPicker(
                    textEditingController: _messageController,
                    config: ep.Config(
                      height: 280,
                      emojiViewConfig: ep.EmojiViewConfig(
                        backgroundColor: const Color(0xFFEFEAE2),
                        columns: 8,
                        emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                      ),
                      categoryViewConfig: const ep.CategoryViewConfig(
                        indicatorColor: Color(0xFF006A4E),
                        iconColorSelected: Color(0xFF006A4E),
                        iconColor: Color(0xFF667781),
                        backgroundColor: Color(0xFFEFEAE2),
                      ),
                      bottomActionBarConfig: const ep.BottomActionBarConfig(
                        backgroundColor: Color(0xFFEFEAE2),
                        buttonColor: Color(0xFF006A4E),
                      ),
                      searchViewConfig: const ep.SearchViewConfig(
                        backgroundColor: Color(0xFFEFEAE2),
                      ),
                    ),
                  ),
                ),
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
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: kOnSurfaceVariant,
                    ),
                    onPressed: _toggleEmojiPicker,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
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
                    _isUploadingMedia
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.camera_alt_outlined, color: kOnSurfaceVariant),
                            onPressed: _pickAndSendImage,
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

  Widget _buildLiveTypingBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 60, bottom: 2, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFF006A4E).withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF111B21).withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 11, color: Color(0xFF006A4E)),
          ],
        ),
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
