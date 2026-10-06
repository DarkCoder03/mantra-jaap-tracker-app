import 'date_utils.dart';

class StreakInfo {
  /// Consecutive qualifying days ending today, or ending yesterday if today
  /// has not qualified yet (the streak is still alive until midnight).
  final int current;

  /// Longest run of consecutive qualifying days ever.
  final int best;

  /// Whether today already counts toward the streak.
  final bool doneToday;

  const StreakInfo({required this.current, required this.best, required this.doneToday});

  static const empty = StreakInfo(current: 0, best: 0, doneToday: false);
}

/// A day qualifies when at least [threshold] chants were logged (by default
/// the app passes one full mala / cycle).
StreakInfo computeStreak(
  Map<String, int> countsByDate, {
  required int threshold,
  DateTime? now,
}) {
  final minimum = threshold < 1 ? 1 : threshold;
  final todayDate = dateOnly(now ?? DateTime.now());
  bool qualifies(DateTime d) => (countsByDate[isoDate(d)] ?? 0) >= minimum;

  final doneToday = qualifies(todayDate);
  var cursor = doneToday ? todayDate : addDays(todayDate, -1);
  var current = 0;
  while (qualifies(cursor)) {
    current++;
    cursor = addDays(cursor, -1);
  }

  final days = countsByDate.entries
      .where((e) => e.value >= minimum)
      .map((e) => DateTime.tryParse(e.key))
      .whereType<DateTime>()
      .map(dateOnly)
      .toList()
    ..sort();

  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final d in days) {
    run = (previous != null && addDays(previous, 1) == d) ? run + 1 : 1;
    if (run > best) best = run;
    previous = d;
  }
  if (current > best) best = current;

  return StreakInfo(current: current, best: best, doneToday: doneToday);
}
