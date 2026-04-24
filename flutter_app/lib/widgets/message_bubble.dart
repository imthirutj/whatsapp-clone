import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../services/api_service.dart';

const _kQuickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTail;
  final bool isHighlighted;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;
  final Function(String emoji)? onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTail,
    this.isHighlighted = false,
    this.onReply,
    this.onReplyTap,
    this.onReact,
  });

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isMe 
        ? Colors.white.withValues(alpha: 0.7) 
        : (isDark ? kOnSurfaceVariantDark : const Color(0xFF667781));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.inter(
            color: subTextColor,
            fontSize: 11,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            (isRead || isDelivered) ? Icons.done_all : Icons.done,
            size: 16,
            color: isRead ? const Color(0xFF53BDEB) : Colors.white.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }

  BoxDecoration _bubbleDecoration(bool isMe, bool isDark) => BoxDecoration(
    color: isMe 
        ? (isDark ? kOutgoingBubbleDark : const Color(0xFF005D4B)) 
        : (isDark ? kIncomingBubbleDark : Colors.white),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(showTail && !isMe ? 2 : 16),
      topRight: Radius.circular(showTail && isMe ? 2 : 16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    ),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 1, offset: const Offset(0, 1)),
    ],
  );

  Widget _buildReplyQuote(Message reply, bool isMe, bool isDark, {VoidCallback? onTap}) {
    final quoteBg = isMe
        ? Colors.white.withValues(alpha: 0.15)
        : (isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF006A4E).withValues(alpha: 0.08));
    final barColor = isMe ? Colors.white.withValues(alpha: 0.6) : (isDark ? kPrimaryDark : const Color(0xFF006A4E));
    final textColor = isMe ? Colors.white.withValues(alpha: 0.9) : (isDark ? kOnSurfaceDark : const Color(0xFF111B21));
    final subTextColor = isMe ? Colors.white.withValues(alpha: 0.7) : (isDark ? kOnSurfaceVariantDark : const Color(0xFF667781));

    final previewText = reply.type == 'image' ? '📷 Photo' : reply.text;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: quoteBg,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: barColor, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reply.sender.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              previewText,
              style: GoogleFonts.inter(fontSize: 12, color: subTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Aggregate reactions: { emoji -> count }
  Map<String, int> _aggregateReactions() {
    final result = <String, int>{};
    for (final emoji in message.reactions.values) {
      result[emoji] = (result[emoji] ?? 0) + 1;
    }
    return result;
  }

  Widget _buildReactions(Map<String, int> aggregated, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 12,
        right: isMe ? 12 : 0,
        top: 2,
        bottom: 2,
      ),
      child: Wrap(
        spacing: 4,
        children: aggregated.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? kIncomingBubbleDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2),
              ],
            ),
            child: Text(
              e.value > 1 ? '${e.key} ${e.value}' : e.key,
              style: const TextStyle(fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptionsSheet(
        onEmojiSelected: (emoji) {
          Navigator.pop(context);
          onReact?.call(emoji);
        },
        onReply: () {
          Navigator.pop(context);
          onReply?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(message.createdAt);
    final isRead = message.status == 'read';
    final isDelivered = message.status == 'delivered';
    final aggregatedReactions = _aggregateReactions();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isHighlighted ? kPrimary.withValues(alpha: 0.12) : Colors.transparent,
      padding: EdgeInsets.only(
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
        top: showTail ? 8 : 2,
        bottom: 0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: () => _showOptions(context),
              child: message.type == 'image'
                  ? _ImageBubble(
                      message: message,
                      isMe: isMe,
                      timeStr: timeStr,
                      isRead: isRead,
                      isDelivered: isDelivered,
                      decoration: _bubbleDecoration(isMe, isDark),
                      statusRow: _buildStatusRow(isMe, timeStr, isRead, isDelivered),
                      replyQuote: message.replyTo != null
                          ? _buildReplyQuote(message.replyTo!, isMe, isDark, onTap: onReplyTap)
                          : null,
                    )
                  : Container(
                      decoration: _bubbleDecoration(isMe, isDark),
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.replyTo != null)
                            _buildReplyQuote(message.replyTo!, isMe, isDark, onTap: onReplyTap),
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                message.text,
                                style: GoogleFonts.inter(
                                  color: isMe ? Colors.white : (isDark ? kOnSurfaceDark : const Color(0xFF111B21)),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: _buildStatusRow(isMe, timeStr, isRead, isDelivered),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            if (aggregatedReactions.isNotEmpty)
              _buildReactions(aggregatedReactions, isMe),
          ],
        ),
      ),
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final VoidCallback onReply;

  const _MessageOptionsSheet({
    required this.onEmojiSelected,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick emoji row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _kQuickEmojis.map((e) {
                return GestureDetector(
                  onTap: () => onEmojiSelected(e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF0F2F5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Reply option
          InkWell(
            onTap: onReply,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Color(0xFF006A4E)),
                  const SizedBox(width: 12),
                  Text(
                    'Reply',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? kOnSurfaceDark : const Color(0xFF111B21),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String timeStr;
  final bool isRead;
  final bool isDelivered;
  final BoxDecoration decoration;
  final Widget statusRow;
  final Widget? replyQuote;

  const _ImageBubble({
    required this.message,
    required this.isMe,
    required this.timeStr,
    required this.isRead,
    required this.isDelivered,
    required this.decoration,
    required this.statusRow,
    this.replyQuote,
  });

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  Uint8List? _imageBytes;
  bool _loading = false;

  Future<void> _loadAndShow() async {
    if (_imageBytes != null) {
      _showFullscreen();
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes = await ApiService().fetchMediaBytes(widget.message.text);
      if (mounted) setState(() => _imageBytes = Uint8List.fromList(bytes));
      _showFullscreen();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFullscreen() {
    if (_imageBytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(_imageBytes!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = widget.isMe 
        ? Colors.white.withValues(alpha: 0.7) 
        : (isDark ? kOnSurfaceVariantDark : const Color(0xFF667781));

    return GestureDetector(
      onTap: _loadAndShow,
      child: Container(
        width: 180,
        decoration: widget.decoration,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.replyQuote != null) ...[
              widget.replyQuote!,
              const SizedBox(height: 6),
            ],
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.12)
                    : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: kPrimary)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo,
                            size: 36,
                            color: subTextColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to view',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: widget.statusRow,
            ),
          ],
        ),
      ),
    );
  }
}
