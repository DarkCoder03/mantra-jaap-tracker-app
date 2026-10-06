import 'package:flutter_test/flutter_test.dart';
import 'package:mantra_jaap_tracker/utils/date_utils.dart';
import 'package:mantra_jaap_tracker/utils/streak.dart';

void main() {
  // Mid-afternoon, so nothing depends on the clock being at midnight.
  final now = DateTime(2026, 10, 6, 15, 30);

  Map<String, int> daysAgo(List<int> offsets, {int count = 108}) => {
        for (final o in offsets) isoDate(addDays(dateOnly(now), -o)): count,
      };

  test('counts consecutive days including today', () {
    final s = computeStreak(daysAgo([0, 1, 2]), threshold: 108, now: now);
    expect(s.current, 3);
    expect(s.best, 3);
    expect(s.doneToday, isTrue);
  });

  test('streak stays alive until today is finished', () {
    final s = computeStreak(daysAgo([1, 2, 3, 4]), threshold: 108, now: now);
    expect(s.current, 4);
    expect(s.doneToday, isFalse);
  });

  test('a missed day breaks the current streak but not the best', () {
    final s = computeStreak(daysAgo([0, 1, 3, 4, 5]), threshold: 108, now: now);
    expect(s.current, 2);
    expect(s.best, 3);
  });

  test('missing both today and yesterday means no current streak', () {
    final s = computeStreak(daysAgo([2, 3]), threshold: 108, now: now);
    expect(s.current, 0);
    expect(s.best, 2);
  });

  test('days below one full mala do not count', () {
    final counts = {
      ...daysAgo([0], count: 107),
      ...daysAgo([1]),
    };
    final s = computeStreak(counts, threshold: 108, now: now);
    expect(s.current, 1);
    expect(s.doneToday, isFalse);
  });

  test('best streak runs across a month boundary', () {
    final counts = {
      '2026-09-29': 108,
      '2026-09-30': 200,
      '2026-10-01': 108,
      '2026-10-02': 500,
    };
    final s = computeStreak(counts, threshold: 108, now: now);
    expect(s.current, 0);
    expect(s.best, 4);
  });

  test('empty history', () {
    final s = computeStreak({}, threshold: 108, now: now);
    expect(s.current, 0);
    expect(s.best, 0);
    expect(s.doneToday, isFalse);
  });
}
