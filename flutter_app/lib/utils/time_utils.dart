import 'package:intl/intl.dart';

class TimeUtils {
  static String formatMessageTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(local);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDay == yesterday) {
      return 'Yesterday';
    }

    final daysAgo = today.difference(messageDay).inDays;
    if (daysAgo < 7) {
      return DateFormat('EEEE').format(local);
    }

    return DateFormat('dd/MM/yy').format(local);
  }

  static String formatChatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);

    if (msgDay == today) {
      return DateFormat('HH:mm').format(local);
    }
    final daysAgo = today.difference(msgDay).inDays;
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat('EEE').format(local);
    return DateFormat('dd/MM/yy').format(local);
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
