import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterProfile {
  String id;
  String name;
  Map<String, int> countsByDate;

  CounterProfile({
    required this.id,
    required this.name,
    required this.countsByDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'countsByDate': countsByDate,
  };

  factory CounterProfile.fromMap(Map<String, dynamic> m) => CounterProfile(
    id: m['id'],
    name: m['name'],
    countsByDate: Map<String, int>.from(m['countsByDate'] ?? {}),
  );
}

class CounterProvider extends ChangeNotifier {
  static const _key = 'counter_store_v3';

  List<CounterProfile> counters = [];
  String? activeCounterId;

  CounterProfile? get activeCounter {
    if (counters.isEmpty) return null;
    return counters.firstWhere(
          (c) => c.id == activeCounterId,
      orElse: () => counters.first,
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final m = jsonDecode(raw) as Map<String, dynamic>;
    counters = (m['counters'] as List<dynamic>? ?? [])
        .map((e) => CounterProfile.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    activeCounterId = m['activeCounterId'];

    if (counters.isNotEmpty && activeCounterId == null) {
      activeCounterId = counters.first.id;
    }

    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'counters': counters.map((e) => e.toMap()).toList(),
      'activeCounterId': activeCounterId,
    };
    await prefs.setString(_key, jsonEncode(m));
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> ensureFirstCounter(String name) async {
    if (counters.isNotEmpty) return;
    final c = CounterProfile(id: _uid(), name: name, countsByDate: {});
    counters = [c];
    activeCounterId = c.id;
    notifyListeners();
    await save();
  }

  Future<void> addCounter(String name) async {
    if (name.trim().isEmpty) return;
    final c = CounterProfile(id: _uid(), name: name.trim(), countsByDate: {});
    counters.add(c);
    activeCounterId = c.id;
    notifyListeners();
    await save();
  }

  Future<void> renameCounter(String id, String name) async {
    final idx = counters.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    counters[idx].name = name.trim();
    notifyListeners();
    await save();
  }

  Future<void> removeCounter(String id) async {
    if (counters.length <= 1) return;
    counters.removeWhere((e) => e.id == id);
    if (!counters.any((e) => e.id == activeCounterId)) {
      activeCounterId = counters.first.id;
    }
    notifyListeners();
    await save();
  }

  Future<void> switchCounter(String id) async {
    activeCounterId = id;
    notifyListeners();
    await save();
  }

  int countForDate(String isoDate) {
    final c = activeCounter;
    if (c == null) return 0;
    return c.countsByDate[isoDate] ?? 0;
  }

  Future<void> setCountForDate(String isoDate, int value) async {
    final c = activeCounter;
    if (c == null) return;
    c.countsByDate[isoDate] = value;
    notifyListeners();
    await save();
  }

  Future<void> increment(String isoDate) async {
    final v = countForDate(isoDate) + 1;
    await setCountForDate(isoDate, v);
  }

  Future<void> decrement(String isoDate) async {
    final cur = countForDate(isoDate);
    if (cur <= 0) return;
    await setCountForDate(isoDate, cur - 1);
  }

  Future<void> resetDay(String isoDate) async {
    await setCountForDate(isoDate, 0);
  }

  Map<String, dynamic> toBackupMap() {
    return {
      "activeCounterId": activeCounterId,
      "counters": counters
          .map((c) => {
        "id": c.id,
        "name": c.name,
        "countsByDate": c.countsByDate,
      })
          .toList(),
    };
  }

  Future<void> importFromMap(Map<String, dynamic> storeMap) async {
    counters = (storeMap['counters'] as List<dynamic>? ?? [])
        .map((e) => CounterProfile.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    activeCounterId = storeMap['activeCounterId'];
    if (counters.isNotEmpty && activeCounterId == null) {
      activeCounterId = counters.first.id;
    }
    notifyListeners();
    await save();
  }
}