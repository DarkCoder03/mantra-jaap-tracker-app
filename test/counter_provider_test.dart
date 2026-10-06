import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantra_jaap_tracker/models/mantra_icon.dart';
import 'package:mantra_jaap_tracker/providers/counter_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v1 data loads with its old calendar colours and sensible defaults', () async {
    // Exactly what v1.0.0 wrote: no iconId, colorValue or dailyGoalCycles.
    SharedPreferences.setMockInitialValues({
      'counter_store_v3': jsonEncode({
        'activeCounterId': 'b',
        'counters': [
          {'id': 'a', 'name': 'Gayatri', 'countsByDate': {'2026-10-01': 216}},
          {'id': 'b', 'name': 'Hare Krishna', 'countsByDate': {}},
        ],
      }),
    });

    final cp = CounterProvider();
    await cp.load();

    expect(cp.counters, hasLength(2));
    expect(cp.activeCounter?.name, 'Hare Krishna');
    expect(cp.counters[0].color, CounterProvider.palette[0]);
    expect(cp.counters[1].color, CounterProvider.palette[1]);
    expect(cp.counters[0].iconId, MantraIcons.fallbackId);
    expect(cp.counters[0].dailyGoalCycles, 1);
    expect(cp.counters[0].countsByDate['2026-10-01'], 216);
  });

  test('new fields survive a save and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final cp = CounterProvider();
    await cp.addCounter('Om Namah Shivaya', iconId: 'shiv', dailyGoalCycles: 5);
    await cp.increment('2026-10-06');

    final reloaded = CounterProvider();
    await reloaded.load();
    final c = reloaded.activeCounter!;
    expect(c.iconId, 'shiv');
    expect(c.dailyGoalCycles, 5);
    expect(c.countsByDate['2026-10-06'], 1);
  });

  test('resetting a day removes it instead of storing zero', () async {
    SharedPreferences.setMockInitialValues({});
    final cp = CounterProvider();
    await cp.addCounter('Test');
    await cp.increment('2026-10-06');
    await cp.resetDay('2026-10-06');
    expect(cp.activeCounter!.countsByDate.containsKey('2026-10-06'), isFalse);
  });

  test('counters on removed symbols keep their look', () async {
    SharedPreferences.setMockInitialValues({
      'counter_store_v3': jsonEncode({
        'activeCounterId': 'a',
        'counters': [
          {'id': 'a', 'name': 'Om', 'countsByDate': {}, 'iconId': 'om'},
          {'id': 'b', 'name': 'Shiva', 'countsByDate': {}, 'iconId': 'shiva'},
          {'id': 'c', 'name': 'Unknown', 'countsByDate': {}, 'iconId': 'does-not-exist'},
        ],
      }),
    });

    final cp = CounterProvider();
    await cp.load();

    expect(cp.counters[0].iconId, MantraIcons.customId);
    expect(cp.counters[0].customGlyph, 'ॐ');
    expect(cp.counters[1].iconId, 'shiv');
    expect(cp.counters[2].iconId, MantraIcons.fallbackId);
  });
}