import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String format([String pattern = 'dd MMM yyyy']) => DateFormat(pattern).format(this);

  String get dayMonthYear => format();

  String get dayMonthYearTime => format('dd MMM yyyy, HH:mm');

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
}

extension NullableDateTimeExt on DateTime? {
  String formatOr(String fallback, [String pattern = 'dd MMM yyyy']) {
    final value = this;
    return value == null ? fallback : value.format(pattern);
  }
}
