import 'package:intl/intl.dart';

class TimeUtils {
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(dateTime);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDay == yesterday) {
      return 'Yesterday';
    }

    final daysAgo = today.difference(messageDay).inDays;
    if (daysAgo < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    }

    return DateFormat('dd/MM/yy').format(dateTime);
  }

  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDay == today) {
      return DateFormat('HH:mm').format(dateTime);
    }
    final daysAgo = today.difference(msgDay).inDays;
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat('EEE').format(dateTime);
    return DateFormat('dd/MM/yy').format(dateTime);
  }

  static String formatDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDay == today) return 'Today';

    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday';

    final daysAgo = today.difference(msgDay).inDays;
    if (daysAgo < 7) return DateFormat('EEEE').format(dateTime);

    return DateFormat('MMMM d, y').format(dateTime);
  }

  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'last seen recently';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'last seen just now';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    return 'last seen on ${DateFormat('MMM d').format(lastSeen)}';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
