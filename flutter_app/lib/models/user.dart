class User {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? phone;
  final String avatarColor;
  final String bio;
  final bool online;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.phone,
    required this.avatarColor,
    required this.bio,
    required this.online,
    this.lastSeen,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarColor: json['avatarColor']?.toString() ?? '#006A4E',
      bio: json['bio']?.toString() ?? '',
      online: json['online'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarColor': avatarColor,
      'bio': bio,
      'online': online,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? avatarColor,
    String? bio,
    bool? online,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarColor: avatarColor ?? this.avatarColor,
      bio: bio ?? this.bio,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
