import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat.dart';
import '../widgets/avatar_widget.dart';
import '../utils/time_utils.dart';
import '../constants.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = chat.otherUser(currentUserId);
    final displayName = chat.displayName(currentUserId);
    final lastMessage = chat.lastMessage;
    final unreadCount = chat.unreadCount;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            if (otherUser != null)
              AvatarWidget(
                user: otherUser,
                size: 50,
                showOnlineIndicator: true,
              )
            else
              const CircleAvatar(
                radius: 25,
                child: Icon(Icons.group),
              ),
            const SizedBox(width: 14),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Time row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessage != null) ...[
                        if (lastMessage.sender.id == currentUserId)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              lastMessage.status == 'read' || lastMessage.status == 'delivered'
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: lastMessage.status == 'read'
                                  ? const Color(0xFF53BDEB)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          TimeUtils.formatChatTime(lastMessage.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: unreadCount > 0 ? kPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message preview + badge row
                  Row(
                    children: [
                      Expanded(
                        child: lastMessage?.type == 'image'
                            ? Row(
                                children: [
                                  const Icon(Icons.photo, size: 16, color: kOnSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Photo',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                lastMessage?.text ?? 'No messages yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
