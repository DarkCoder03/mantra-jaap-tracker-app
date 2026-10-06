import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mantra_icon.dart';
import '../utils/date_utils.dart';
import '../utils/streak.dart';

class CounterProfile {
  String id;
  String name;
  Map<String, int> countsByDate;

  /// Symbol shown in lists, the home card and the counter screen.
  String iconId;

  /// Identity colour: calendar dots and the avatar tint.
  int colorValue;

  /// Daily goal in full cycles (malas). Always at least 1.
  int dailyGoalCycles;

  /// Text shown when [iconId] is "custom" (e.g. ॐ, 🙏 or a short word).
  String? customGlyph;

  CounterProfile({
    required this.id,
    required this.name,
    required this.countsByDate,
    this.iconId = MantraIcons.fallbackId,
    this.colorValue = 0,
    this.dailyGoalCycles = 1,
    this.customGlyph,
  });

  Color get color => Color(colorValue);
  MantraIcon get icon => MantraIcons.byId(iconId);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'countsByDate': countsByDate,
        'iconId': iconId,
        'colorValue': colorValue,
        'dailyGoalCycles': dailyGoalCycles,
        if (customGlyph != null) 'customGlyph': customGlyph,
      };

  factory CounterProfile.fromMap(Map<String, dynamic> m) {
    final rawCounts = m['countsByDate'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        if (v is num) counts[k.toString()] = v.toInt();
      });
    }
    return CounterProfile(
      id: m['id'].toString(),
      name: (m['name'] ?? 'Counter').toString(),
      countsByDate: counts,
      iconId: (m['iconId'] as String?) ?? MantraIcons.fallbackId,
      colorValue: (m['colorValue'] as num?)?.toInt() ?? 0,
      dailyGoalCycles: ((m['dailyGoalCycles'] as num?)?.toInt() ?? 1).clamp(1, 999),
      customGlyph: m['customGlyph'] as String?,
    );
  }
}

class CounterProvider extends ChangeNotifier {
  static const _key = 'counter_store_v3';

  /// Counter identity colours. Order matches v1's dot palette so existing
  /// counters keep the colour they already had on the calendar.
  static const List<Color> palette = [
    Color(0xFF14B8A6),
    Color(0xFFA855F7),
    Color(0xFFF43F5E),
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFF84CC16),
  ];

  List<CounterProfile> counters = [];
  String? activeCounterId;

  CounterProfile? get activeCounter {
    if (counters.isEmpty) return null;
    return counters.firstWhere(
      (c) => c.id == activeCounterId,
      orElse: () => counters.first,
    );
  }

  CounterProfile? byId(String id) {
    for (final c in counters) {
      if (c.id == id) return c;
    }
    return null;
  }

  Color nextColor() => palette[counters.length % palette.length];

  /// Fills fields that older saves and backups don't have, and moves
  /// counters off symbols that no longer exist without changing their look.
  void _migrate() {
    for (var i = 0; i < counters.length; i++) {
      final c = counters[i];
      if (c.colorValue == 0) c.colorValue = palette[i % palette.length].toARGB32();
      if (!MantraIcons.exists(c.iconId)) {
        final renamed = MantraIcons.legacyIds[c.iconId];
        final glyph = MantraIcons.legacyGlyphs[c.iconId];
        if (renamed != null) {
          c.iconId = renamed;
        } else if (glyph != null) {
          c.iconId = MantraIcons.customId;
          c.customGlyph ??= glyph;
        } else {
          c.iconId = MantraIcons.fallbackId;
        }
      }
    }
    if (counters.isNotEmpty && !counters.any((c) => c.id == activeCounterId)) {
      activeCounterId = counters.first.id;
    }
  }

  List<CounterProfile> _parseCounters(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CounterProfile.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final m = jsonDecode(raw) as Map<String, dynamic>;
    counters = _parseCounters(m['counters']);
    activeCounterId = m['activeCounterId'] as String?;
    _migrate();
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toBackupMap()));
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _commit() async {
    notifyListeners();
    await save();
  }

  // ---------------------------------------------------------------------------
  // Counters

  Future<CounterProfile?> addCounter(
    String name, {
    String iconId = MantraIcons.fallbackId,
    Color? color,
    int dailyGoalCycles = 1,
    String? customGlyph,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final c = CounterProfile(
      id: _uid(),
      name: trimmed,
      countsByDate: {},
      iconId: iconId,
      colorValue: (color ?? nextColor()).toARGB32(),
      dailyGoalCycles: dailyGoalCycles.clamp(1, 999),
      customGlyph: _cleanGlyph(customGlyph),
    );
    counters.add(c);
    activeCounterId = c.id;
    await _commit();
    return c;
  }

  /// Pass [customGlyph] as an empty string to clear it.
  Future<void> updateCounter(
    String id, {
    String? name,
    String? iconId,
    Color? color,
    int? dailyGoalCycles,
    String? customGlyph,
  }) async {
    final c = byId(id);
    if (c == null) return;
    if (name != null && name.trim().isNotEmpty) c.name = name.trim();
    if (iconId != null) c.iconId = iconId;
    if (color != null) c.colorValue = color.toARGB32();
    if (dailyGoalCycles != null) c.dailyGoalCycles = dailyGoalCycles.clamp(1, 999);
    if (customGlyph != null) c.customGlyph = _cleanGlyph(customGlyph);
    await _commit();
  }

  static String? _cleanGlyph(String? glyph) {
    final t = glyph?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  Future<void> renameCounter(String id, String name) => updateCounter(id, name: name);

  Future<void> setDailyGoal(String id, int cycles) => updateCounter(id, dailyGoalCycles: cycles);

  Future<void> removeCounter(String id) async {
    if (counters.length <= 1) return;
    counters.removeWhere((e) => e.id == id);
    if (!counters.any((e) => e.id == activeCounterId)) {
      activeCounterId = counters.first.id;
    }
    await _commit();
  }

  Future<void> switchCounter(String id) async {
    if (activeCounterId == id) return;
    activeCounterId = id;
    await _commit();
  }

  // ---------------------------------------------------------------------------
  // Counts (active counter)

  int countForDate(String isoDate) => activeCounter?.countsByDate[isoDate] ?? 0;

  Future<void> setCountForDate(String isoDate, int value) async {
    final c = activeCounter;
    if (c == null) return;
    if (value <= 0) {
      c.countsByDate.remove(isoDate);
    } else {
      c.countsByDate[isoDate] = value;
    }
    await _commit();
  }

  Future<void> increment(String isoDate) => setCountForDate(isoDate, countForDate(isoDate) + 1);

  Future<void> decrement(String isoDate) async {
    final cur = countForDate(isoDate);
    if (cur <= 0) return;
    await setCountForDate(isoDate, cur - 1);
  }

  Future<void> resetDay(String isoDate) => setCountForDate(isoDate, 0);

  // ---------------------------------------------------------------------------
  // Aggregates

  /// Chants on a day for one counter, or across all counters when [counterId]
  /// is null.
  int chantsOn(DateTime day, {String? counterId}) {
    final key = isoDate(day);
    if (counterId != null) return byId(counterId)?.countsByDate[key] ?? 0;
    var total = 0;
    for (final c in counters) {
      total += c.countsByDate[key] ?? 0;
    }
    return total;
  }

  /// Every counter's chants summed per day.
  Map<String, int> combinedCounts() {
    final out = <String, int>{};
    for (final c in counters) {
      c.countsByDate.forEach((k, v) => out[k] = (out[k] ?? 0) + v);
    }
    return out;
  }

  /// Streak for one counter (the active one by default) or, with
  /// [allCounters], for chanting on any counter. A day counts once at least
  /// one full cycle was completed.
  StreakInfo streak({required int cycleSize, String? counterId, bool allCounters = false}) {
    final Map<String, int> counts;
    if (allCounters) {
      counts = combinedCounts();
    } else {
      final c = counterId != null ? byId(counterId) : activeCounter;
      if (c == null) return StreakInfo.empty;
      counts = c.countsByDate;
    }
    return computeStreak(counts, threshold: cycleSize);
  }

  // ---------------------------------------------------------------------------
  // Backup

  Map<String, dynamic> toBackupMap() => {
        'activeCounterId': activeCounterId,
        'counters': counters.map((c) => c.toMap()).toList(),
      };

  Future<void> importFromMap(Map<String, dynamic> storeMap) async {
    counters = _parseCounters(storeMap['counters']);
    activeCounterId = storeMap['activeCounterId'] as String?;
    _migrate();
    await _commit();
  }
}