import 'user.dart';

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String text;
  final String type;
  final String status;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.text,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
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
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
    };
  }
}
