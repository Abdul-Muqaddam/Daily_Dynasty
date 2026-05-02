import 'package:cloud_firestore/cloud_firestore.dart';

class DraftScheduleService {
  /// Returns the next global draft date based on the current date.
  /// Drafts occur on the 14th and the last day (30th/31st) of every month.
  static DateTime getNextGlobalDraftDate() {
    final now = DateTime.now();
    
    // Check if 14th of this month is still in the future
    final draft14th = DateTime(now.year, now.month, 14);
    if (now.isBefore(draft14th)) {
      return draft14th;
    }
    
    // Check if end of this month is in the future
    final lastDay = DateTime(now.year, now.month + 1, 0);
    if (now.isBefore(lastDay)) {
      return lastDay;
    }
    
    // Otherwise, next draft is 14th of next month
    return DateTime(now.year, now.month + 1, 14);
  }

  /// Returns a formatted string for the next draft date.
  static String getFormattedNextDraftDate() {
    final nextDate = getNextGlobalDraftDate();
    final months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return "${months[nextDate.month]} ${nextDate.day}, ${nextDate.year}";
  }

  /// Checks if today is a global draft day.
  static bool isDraftDay() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return now.day == 14 || now.day == lastDay.day;
  }
}
