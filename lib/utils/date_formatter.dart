import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime date) {
    return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(date);
  }
  static String formatShortDate(DateTime date) {
    return DateFormat("dd/MM/yyyy", "id_ID").format(date);
  }
  static String formatDayMonth(DateTime date) {
    return DateFormat("dd MMMM", "id_ID").format(date);
  }
  static String formatTime(DateTime date) {
    return DateFormat("HH:mm", "id_ID").format(date);
  }
  static String formatApiDate(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }
}
