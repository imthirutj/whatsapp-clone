import 'user.dart';

class Status {
  final String id;
  final User user;
  final String? text;
  final String backgroundColor;
  final List<String> viewers;
  final DateTime expiresAt;
  final DateTime createdAt;

  const Status({
    required this.id,
    required this.user,
    this.text,
    required this.backgroundColor,
    required this.viewers,
    required this.expiresAt,
    required this.createdAt,
  });

  bool isViewed(String userId) => viewers.contains(userId);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Status.fromJson(Map<String, dynamic> json) {
    final viewersList = (json['viewers'] as List<dynamic>? ?? [])
        .map((v) => v.toString())
        .toList();

    return Status(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : User(
              id: json['user']?.toString() ?? '',
              name: 'Unknown',
              email: '',
              avatarColor: '#006A4E',
              bio: '',
              online: false,
            ),
      text: json['text']?.toString(),
      backgroundColor: json['backgroundColor']?.toString() ?? '#006A4E',
      viewers: viewersList,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString()) ??
              DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'text': text,
      'backgroundColor': backgroundColor,
      'viewers': viewers,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
