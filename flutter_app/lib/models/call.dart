import 'user.dart';

class Call {
  final String id;
  final User caller;
  final User receiver;
  final String type; // 'audio', 'video'
  final String status; // 'missed', 'answered', 'rejected'
  final int duration; // seconds
  final DateTime createdAt;

  const Call({
    required this.id,
    required this.caller,
    required this.receiver,
    required this.type,
    required this.status,
    required this.duration,
    required this.createdAt,
  });

  bool get isMissed => status == 'missed';

  String get formattedDuration {
    if (duration <= 0) return '';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      caller: json['caller'] is Map<String, dynamic>
          ? User.fromJson(json['caller'] as Map<String, dynamic>)
          : User(
              id: json['caller']?.toString() ?? '',
              name: 'Unknown',
              email: '',
              avatarColor: '#006A4E',
              bio: '',
              online: false,
            ),
      receiver: json['receiver'] is Map<String, dynamic>
          ? User.fromJson(json['receiver'] as Map<String, dynamic>)
          : User(
              id: json['receiver']?.toString() ?? '',
              name: 'Unknown',
              email: '',
              avatarColor: '#006A4E',
              bio: '',
              online: false,
            ),
      type: json['type']?.toString() ?? 'audio',
      status: json['status']?.toString() ?? 'missed',
      duration: json['duration'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller': caller.toJson(),
      'receiver': receiver.toJson(),
      'type': type,
      'status': status,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
