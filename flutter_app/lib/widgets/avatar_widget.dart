import 'package:flutter/material.dart';
import '../models/user.dart';

class AvatarWidget extends StatelessWidget {
  final User user;
  final double size;
  final bool showOnlineIndicator;

  const AvatarWidget({
    super.key,
    required this.user,
    this.size = 48,
    this.showOnlineIndicator = false,
  });

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF006A4E);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(user.avatarColor);
    final textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: bgColor,
          child: Text(
            user.initials,
            style: TextStyle(
              color: textColor,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showOnlineIndicator && user.online)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
