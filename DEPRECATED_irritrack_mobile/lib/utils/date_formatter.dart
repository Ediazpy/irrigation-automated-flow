import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats date as "Monday 1/2/26"
  static String formatInspectionDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayOfWeek = DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
      final shortDate = DateFormat('M/d/yy').format(date); // 1/2/26
      return '$dayOfWeek $shortDate';
    } catch (e) {
      return dateStr;
    }
  }

  /// Formats date as "Monday 1/2/26" from DateTime object
  static String formatDateTime(DateTime date) {
    final dayOfWeek = DateFormat('EEEE').format(date);
    final shortDate = DateFormat('M/d/yy').format(date);
    return '$dayOfWeek $shortDate';
  }

  /// For grouping - just returns the date string for comparison
  static String getDateKey(String dateStr) {
    return dateStr;
  }
}
