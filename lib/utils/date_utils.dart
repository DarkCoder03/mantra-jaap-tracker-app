import 'package:intl/intl.dart';

final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

/// Storage key for a day, e.g. `2026-10-06`.
String isoDate(DateTime d) => _isoFormat.format(d);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime today() => dateOnly(DateTime.now());

/// Calendar arithmetic via the DateTime constructor, so DST changes never
/// shift a date to 23:00 of the previous day.
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Weeks start on Sunday to match the calendar header.
DateTime startOfWeek(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday % 7));

/// The last [count] days ending today (oldest first).
List<DateTime> lastNDays(int count, {DateTime? now}) {
  final end = dateOnly(now ?? DateTime.now());
  return [for (var i = count - 1; i >= 0; i--) addDays(end, -i)];
}
