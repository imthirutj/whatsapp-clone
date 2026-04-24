import 'user.dart';
import 'message.dart';

class Chat {
  final String id;
  final List<User> participants;
  final bool isGroup;
  final String? groupName;
  final Message? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  const Chat({
    required this.id,
    required this.participants,
    required this.isGroup,
    this.groupName,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final participantsList = (json['participants'] as List<dynamic>? ?? [])
        .map((p) => p is Map<String, dynamic> ? User.fromJson(p) : null)
        .whereType<User>()
        .toList();

    Message? lastMsg;
    if (json['lastMessage'] is Map<String, dynamic>) {
      lastMsg = Message.fromJson(json['lastMessage'] as Map<String, dynamic>);
    }

    return Chat(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: participantsList,
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName']?.toString() ?? json['name']?.toString(),
      lastMessage: lastMsg,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  User? otherUser(String currentUserId) {
    try {
      return participants.firstWhere((u) => u.id != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  String displayName(String currentUserId) {
    if (isGroup && groupName != null && groupName!.isNotEmpty) {
      return groupName!;
    }
    final other = otherUser(currentUserId);
    return other?.name ?? 'Unknown';
  }

  Chat copyWith({
    String? id,
    List<User>? participants,
    bool? isGroup,
    String? groupName,
    Message? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
