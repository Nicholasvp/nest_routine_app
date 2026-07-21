import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String formatTimeAmPm(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';

    return DateFormat('MMM d').format(dt);
  }

  static String formatDateFull(DateTime dt) {
    return DateFormat('EEEE, MMMM d, yyyy').format(dt);
  }

  static String formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    return '${d.inMinutes}min';
  }

  static String formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static DateTime get startOfToday =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static DateTime get startOfWeek {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - now.weekday + 1);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static double getDayProgress() {
    final now = DateTime.now();
    final totalMinutes =
        now.hour * 60 + now.minute;
    return totalMinutes / (24 * 60);
  }

  static double timeToAngle(DateTime dt) {
    final totalMinutes = dt.hour * 60.0 + dt.minute;
    return (totalMinutes / (24 * 60)) * 360;
  }

  static double timeToProgress(DateTime dt) {
    final totalMinutes = dt.hour * 60.0 + dt.minute + dt.second / 60.0;
    return totalMinutes / (24 * 60);
  }

  static DateTime progressToTime(double progress) {
    final totalMinutes = (progress * 24 * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hours.clamp(0, 23),
      minutes.clamp(0, 59),
    );
  }
}
