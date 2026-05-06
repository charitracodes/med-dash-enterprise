import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
  }
}