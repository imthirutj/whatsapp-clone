import 'user.dart';

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String text;
  final String type;
  final String status;
  final DateTime createdAt;
  final Message? replyTo;
  final Map<String, String> reactions;

  const Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.text,
    required this.type,
    required this.status,
    required this.createdAt,
    this.replyTo,
    this.reactions = const {},
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseReactions(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return {};
    }

    return Message(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? json['chat']?.toString() ?? '',
      sender: json['sender'] is Map<String, dynamic>
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : User(
              id: json['sender']?.toString() ?? '',
              name: 'Unknown',
              email: '',
              avatarColor: '#006A4E',
              bio: '',
              online: false,
            ),
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      status: json['status']?.toString() ?? 'sent',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      replyTo: json['replyTo'] is Map<String, dynamic>
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      reactions: parseReactions(json['reactions']),
    );
  }

  Message copyWith({
    String? id,
    String? chatId,
    User? sender,
    String? text,
    String? type,
    String? status,
    DateTime? createdAt,
    Message? replyTo,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'sender': sender.toJson(),
      'text': text,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (replyTo != null) 'replyTo': replyTo!.toJson(),
      'reactions': reactions,
    };
  }
}
