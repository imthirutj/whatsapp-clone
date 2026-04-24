import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../constants.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTail,
  });

  String _formatTime(DateTime time) {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(message.createdAt);
    final isRead = message.status == 'read';

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
        top: showTail ? 8 : 2, // More space between groups, tight space inside group
        bottom: 0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF005D4B) : Colors.white, // Darker WhatsApp Green
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(showTail && !isMe ? 2 : 16),
              topRight: Radius.circular(showTail && isMe ? 2 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                message.text,
                style: GoogleFonts.inter(
                  color: isMe ? Colors.white : const Color(0xFF111B21),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF667781),
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: isRead
                            ? const Color(0xFF53BDEB)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
