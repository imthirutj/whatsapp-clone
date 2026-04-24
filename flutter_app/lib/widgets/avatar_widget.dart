import 'package:flutter/material.dart';
import '../models/user.dart';
import '../constants.dart';

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

  Color _getAvatarColor() {
    // If user has a valid hex color, use it.
    // Otherwise, pick from our vibrant prototype palette based on user ID.
    if (user.avatarColor.isNotEmpty && user.avatarColor != '#006A4E') {
      try {
        final hex = user.avatarColor.replaceAll('#', '');
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }
    
    // Deterministic selection from prototype colors
    final index = user.id.hashCode.abs() % kAvatarColors.length;
    return kAvatarColors[index];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getAvatarColor();
    final textColor = Colors.white; // Prototype uses white for all vibrant avatars

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user.initials,
            style: TextStyle(
              color: textColor,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto', // Matches prototype's clean font
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showOnlineIndicator && user.online)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
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
