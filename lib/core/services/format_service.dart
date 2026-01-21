// i wnat to crete a function for formatting the date

import 'package:intl/intl.dart';

//Nov 19, 2025 – 10:06 AM
String formatDateTime(String date) {
  final utcDate = DateTime.parse(date).toUtc();
  final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));

  return DateFormat('MMM d, yyyy – hh:mm a').format(istDate);
}

String formatDate(String date) {
  final utcDate = DateTime.parse(date).toUtc();
  final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));

  return DateFormat('MMM d, yyyy').format(istDate);
}
