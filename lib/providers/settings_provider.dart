import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stored by name, so new values can be appended safely.
enum AppThemeMode { system, dark, light, amoled }

/// A selectable value with a human label (used by the choice sheets).
class SettingOption<T> {
  final T value;
  final String label;
  final Color? color;
  const SettingOption(this.value, this.label, {this.color});
}

class SettingsProvider extends ChangeNotifier {
  static const _storageKey = 'mantra_settings_v3';

  // --- Option catalogs (single source for every picker in the app) ----------

  static const themeModeOptions = [
    SettingOption(AppThemeMode.system, 'System'),
    SettingOption(AppThemeMode.light, 'Light'),
    SettingOption(AppThemeMode.dark, 'Dark'),
    SettingOption(AppThemeMode.amoled, 'AMOLED black'),
  ];

  static const soundOptions = [
    SettingOption('bell', 'Bell'),
    SettingOption('chime', 'Chime'),
    SettingOption('ghanta', 'Ghanta'),
    SettingOption('damru', 'Damru'),
    SettingOption('flute', 'Flute'),
  ];

  static const primaryThemeOptions = [
    SettingOption('amber', 'Amber', color: Colors.amber),
    SettingOption('rose', 'Rose', color: Colors.pink),
    SettingOption('emerald', 'Emerald', color: Colors.green),
  ];

  static const counterColorOptions = [
    SettingOption('amber', 'Kesari (Amber)', color: Color(0xFFF59E0B)),
    SettingOption('saffron', 'Saffron', color: Color(0xFFF97316)),
    SettingOption('lotus', 'Lotus Pink', color: Color(0xFFEC4899)),
    SettingOption('peacock', 'Peacock Teal', color: Color(0xFF14B8A6)),
    SettingOption('vrindavan', 'Vrindavan Green', color: Color(0xFF10B981)),
    SettingOption('indigo', 'Krishna Indigo', color: Color(0xFF6366F1)),
  ];

  static String labelFor<T>(List<SettingOption<T>> options, T value) =>
      options.firstWhere((o) => o.value == value, orElse: () => options.first).label;

  // --- State -----------------------------------------------------------------

  AppThemeMode themeMode = AppThemeMode.system;
  bool soundAlert = true;
  String soundType = 'bell';
  String primaryThemeKey = 'amber';

  String counterColorKey = 'lotus';
  bool hideMinusButton = false;
  bool regularHaptic = true;
  bool longHaptic = true;
  int cycleSize = 108;

  // v2
  bool calendarCompact = true;
  bool keepScreenOn = true;
  bool volumeKeyCounting = true;
  bool onboardingDone = false;

  bool get isAmoled => themeMode == AppThemeMode.amoled;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark || AppThemeMode.amoled => ThemeMode.dark,
      };

  Color get primaryColor =>
      primaryThemeOptions.firstWhere((o) => o.value == primaryThemeKey, orElse: () => primaryThemeOptions.first).color!;

  /// Colour of the + button, progress rings and today's highlight.
  Color get counterAccentColor =>
      counterColorOptions.firstWhere((o) => o.value == counterColorKey, orElse: () => counterColorOptions[2]).color!;

  /// Deeper shade used for the − button.
  Color get counterAccentDeep => switch (counterColorKey) {
        'amber' => const Color(0xFFB45309),
        'saffron' => const Color(0xFFC2410C),
        'peacock' => const Color(0xFF0F766E),
        'vrindavan' => const Color(0xFF047857),
        'indigo' => const Color(0xFF4338CA),
        _ => const Color(0xFFBE185D),
      };

  // --- Persistence -----------------------------------------------------------

  static AppThemeMode _parseTheme(Object? raw) => AppThemeMode.values.firstWhere(
        (e) => e.name == (raw ?? 'system').toString(),
        orElse: () => AppThemeMode.system,
      );

  /// v1 offered sounds without matching files; map them to ones that exist.
  static String _parseSound(Object? raw) {
    final s = (raw ?? 'bell').toString();
    if (soundOptions.any((o) => o.value == s)) return s;
    return 'bell';
  }

  static int _parseCycle(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 108;
    return n.clamp(1, 100000);
  }

  void _apply(Map<String, dynamic> m) {
    themeMode = _parseTheme(m['themeMode'] ?? m['themeShade']);
    soundAlert = m['soundAlert'] as bool? ?? true;
    soundType = _parseSound(m['soundType']);
    primaryThemeKey = (m['primaryThemeKey'] ?? 'amber').toString();
    counterColorKey = (m['counterColorKey'] ?? 'lotus').toString();
    hideMinusButton = m['hideMinusButton'] as bool? ?? false;
    regularHaptic = m['regularHaptic'] as bool? ?? true;
    longHaptic = m['longHaptic'] as bool? ?? true;
    cycleSize = _parseCycle(m['cycleSize']);
    calendarCompact = m['calendarCompact'] as bool? ?? true;
    keepScreenOn = m['keepScreenOn'] as bool? ?? true;
    volumeKeyCounting = m['volumeKeyCounting'] as bool? ?? true;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _apply(map);
    onboardingDone = map['onboardingDone'] as bool? ?? false;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode({...toBackupMap(), 'onboardingDone': onboardingDone}));
  }

  Future<void> update(VoidCallback mutation) async {
    mutation();
    notifyListeners();
    await save();
  }

  Map<String, dynamic> toBackupMap() => {
        'themeShade': themeMode.name,
        'themeMode': themeMode.name,
        'soundAlert': soundAlert,
        'soundType': soundType,
        'primaryThemeKey': primaryThemeKey,
        'counterColorKey': counterColorKey,
        'hideMinusButton': hideMinusButton,
        'regularHaptic': regularHaptic,
        'longHaptic': longHaptic,
        'cycleSize': cycleSize,
        'calendarCompact': calendarCompact,
        'keepScreenOn': keepScreenOn,
        'volumeKeyCounting': volumeKeyCounting,
      };

  /// Restoring a backup never re-triggers onboarding.
  Future<void> importFromMap(Map<String, dynamic> m) async {
    _apply(m);
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
    calendarCompact = true;
    keepScreenOn = true;
    volumeKeyCounting = true;
    notifyListeners();
    await save();
  }
}
