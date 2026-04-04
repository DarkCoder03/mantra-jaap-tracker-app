import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, dark, light }

class SettingsProvider extends ChangeNotifier {
  static const _storageKey = 'mantra_settings_v3';

  AppThemeMode themeMode = AppThemeMode.system;
  bool soundAlert = true;
  String soundType = 'bell'; // bell | chime | mantra | conch | damru | ghanta | flute
  String primaryThemeKey = 'amber'; // amber | rose | emerald

  String counterColorKey = 'lotus'; // amber | saffron | lotus | peacock | vrindavan | indigo
  bool hideMinusButton = false;
  bool regularHaptic = true;
  bool longHaptic = true;
  int cycleSize = 108;

  Color get primaryColor {
    switch (primaryThemeKey) {
      case 'rose':
        return Colors.pink;
      case 'emerald':
        return Colors.green;
      case 'amber':
      default:
        return Colors.amber;
    }
  }

  Color get counterAccentColor {
    switch (counterColorKey) {
      case 'amber':
        return const Color(0xFFF59E0B);
      case 'saffron':
        return const Color(0xFFF97316);
      case 'lotus':
        return const Color(0xFFEC4899);
      case 'peacock':
        return const Color(0xFF14B8A6);
      case 'vrindavan':
        return const Color(0xFF10B981);
      case 'indigo':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFFEC4899);
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    final map = jsonDecode(raw) as Map<String, dynamic>;

    themeMode = AppThemeMode.values.firstWhere(
          (e) => e.name == (map['themeMode'] ?? 'system'),
      orElse: () => AppThemeMode.system,
    );

    soundAlert = map['soundAlert'] ?? true;
    soundType = map['soundType'] ?? 'bell';
    primaryThemeKey = map['primaryThemeKey'] ?? 'amber';

    counterColorKey = map['counterColorKey'] ?? 'lotus';
    hideMinusButton = map['hideMinusButton'] ?? false;
    regularHaptic = map['regularHaptic'] ?? true;
    longHaptic = map['longHaptic'] ?? true;
    cycleSize = (map['cycleSize'] ?? 108).clamp(1, 100000);

    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'themeMode': themeMode.name,
      'soundAlert': soundAlert,
      'soundType': soundType,
      'primaryThemeKey': primaryThemeKey,
      'counterColorKey': counterColorKey,
      'hideMinusButton': hideMinusButton,
      'regularHaptic': regularHaptic,
      'longHaptic': longHaptic,
      'cycleSize': cycleSize,
    };
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  Future<void> update(VoidCallback mutation) async {
    mutation();
    notifyListeners();
    await save();
  }

  Map<String, dynamic> toBackupMap() {
    return {
      "themeShade": themeMode.name,
      "themeMode": themeMode.name,
      "soundAlert": soundAlert,
      "soundType": soundType,
      "primaryThemeKey": primaryThemeKey,
      "counterColorKey": counterColorKey,
      "hideMinusButton": hideMinusButton,
      "regularHaptic": regularHaptic,
      "longHaptic": longHaptic,
      "cycleSize": cycleSize,
    };
  }

  Future<void> importFromMap(Map<String, dynamic> m) async {
    final themeRaw = (m['themeMode'] ?? m['themeShade'] ?? 'system').toString();

    themeMode = AppThemeMode.values.firstWhere(
          (e) => e.name == themeRaw,
      orElse: () => AppThemeMode.system,
    );

    soundAlert = m['soundAlert'] ?? true;
    soundType = (m['soundType'] ?? 'bell').toString();

    primaryThemeKey = (m['primaryThemeKey'] ?? 'amber').toString();
    counterColorKey = (m['counterColorKey'] ?? 'lotus').toString();

    hideMinusButton = m['hideMinusButton'] ?? false;
    regularHaptic = m['regularHaptic'] ?? true;
    longHaptic = m['longHaptic'] ?? true;

    final cs = m['cycleSize'];
    final parsed = cs is int ? cs : int.tryParse(cs?.toString() ?? '108') ?? 108;
    cycleSize = parsed < 1 ? 1 : parsed;

    notifyListeners();
    await save();
  }

  Future<void> resetToDefaults() async {
    themeMode = AppThemeMode.system;
    soundAlert = true;
    soundType = 'bell';
    primaryThemeKey = 'amber';
    counterColorKey = 'lotus';
    hideMinusButton = false;
    regularHaptic = true;
    longHaptic = true;
    cycleSize = 108;

    notifyListeners();
    await save();
  }
}