import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneService {
  static const String _sastTimezone = 'Africa/Johannesburg';
  
  static void initialize() {
    tz.initializeTimeZones();
  }

  /// Get current time in SAST (Africa/Johannesburg)
  static DateTime nowInSAST() {
    final sastLocation = tz.getLocation(_sastTimezone);
    return tz.TZDateTime.now(sastLocation);
  }

  /// Convert a DateTime to SAST timezone
  static DateTime toSAST(DateTime dateTime) {
    final sastLocation = tz.getLocation(_sastTimezone);
    return tz.TZDateTime.from(dateTime, sastLocation);
  }

  /// Get the start of a day in SAST timezone
  static DateTime startOfDayInSAST(DateTime date) {
    final sastLocation = tz.getLocation(_sastTimezone);
    return tz.TZDateTime(sastLocation, date.year, date.month, date.day, 0, 0, 0);
  }

  /// Get the end of a day in SAST timezone
  static DateTime endOfDayInSAST(DateTime date) {
    final sastLocation = tz.getLocation(_sastTimezone);
    return tz.TZDateTime(sastLocation, date.year, date.month, date.day, 23, 59, 59);
  }

  /// Check if a menu item is orderable based on cutoff rules
  static bool isOrderableForMenuDate(DateTime menuDate, DateTime nowInSAST) {
    final menuDay = DateTime(menuDate.year, menuDate.month, menuDate.day);
    final dayBefore = menuDay.subtract(const Duration(days: 1));
    final cutoff = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 17, 0);
    // if nowInSAST is before cutoff, the menuDate item is still orderable
    return nowInSAST.isBefore(cutoff);
  }

  /// Get the cutoff time for a menu date
  static DateTime getCutoffForMenuDate(DateTime menuDate) {
    final menuDay = DateTime(menuDate.year, menuDate.month, menuDate.day);
    final dayBefore = menuDay.subtract(const Duration(days: 1));
    return DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 17, 0);
  }

  /// Format date for display (e.g., "Mon, 2024-10-07")
  static String formatDateForDisplay(DateTime date) {
    final weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format time for display (e.g., "17:00")
  static String formatTimeForDisplay(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
