import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE4E4E7);
    final cardBg = isDark ? const Color(0xFF121215) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Row(
          children: [
            Icon(PhosphorIcons.gear(), size: 22),
            const SizedBox(width: 10),
            const Text(
              "General Settings",
              style: TextStyle(
                fontFamily: "CormorantGaramond",
                fontSize: 46,
                fontWeight: FontWeight.w600,
                height: 0.9,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SectionTitle("Common settings", color: cs.primary),
          const SizedBox(height: 12),

          const _FieldLabel("Theme shade"),
          DropdownButtonFormField<AppThemeMode>(
            value: sp.themeMode,
            decoration: _inputDec(border, cardBg),
            items: const [
              DropdownMenuItem(value: AppThemeMode.system, child: Text("System")),
              DropdownMenuItem(value: AppThemeMode.dark, child: Text("Dark")),
              DropdownMenuItem(value: AppThemeMode.light, child: Text("Light")),
            ],
            onChanged: (v) => sp.update(() => sp.themeMode = v ?? AppThemeMode.system),
          ),

          const SizedBox(height: 12),
          _SwitchCard(
            title: "Sound alert",
            subtitle: sp.soundAlert ? "Sound alert is ON after each completed cycle" : "Sound alert is OFF",
            value: sp.soundAlert,
            onChanged: (v) => sp.update(() => sp.soundAlert = v),
            borderColor: border,
            cardBg: cardBg,
          ),

          const SizedBox(height: 12),
          const _FieldLabel("Sound type"),
          DropdownButtonFormField<String>(
            value: sp.soundType,
            decoration: _inputDec(border, cardBg),
            items: const [
              DropdownMenuItem(value: 'bell', child: Text('Bell')),
              DropdownMenuItem(value: 'chime', child: Text('Chime')),
              DropdownMenuItem(value: 'mantra', child: Text('Mantra')),
              DropdownMenuItem(value: 'conch', child: Text('Conch')),
              DropdownMenuItem(value: 'damru', child: Text('Damru')),
              DropdownMenuItem(value: 'ghanta', child: Text('Ghanta')),
              DropdownMenuItem(value: 'flute', child: Text('Flute')),
            ],
            onChanged: (v) => sp.update(() => sp.soundType = v ?? 'bell'),
          ),

          const SizedBox(height: 12),
          const _FieldLabel("Colour theme"),
          DropdownButtonFormField<String>(
            value: sp.primaryThemeKey,
            decoration: _inputDec(border, cardBg),
            items: const [
              DropdownMenuItem(value: 'amber', child: Text('Amber')),
              DropdownMenuItem(value: 'rose', child: Text('Rose')),
              DropdownMenuItem(value: 'emerald', child: Text('Emerald')),
            ],
            onChanged: (v) => sp.update(() => sp.primaryThemeKey = v ?? 'amber'),
          ),

          const SizedBox(height: 20),
          Divider(color: border),
          const SizedBox(height: 16),

          _SectionTitle("Counter specific settings", color: cs.primary),
          const SizedBox(height: 12),

          const _FieldLabel("Counter color"),
          DropdownButtonFormField<String>(
            value: sp.counterColorKey,
            decoration: _inputDec(border, cardBg),
            items: const [
              DropdownMenuItem(value: 'amber', child: Text('Kesari (Amber)')),
              DropdownMenuItem(value: 'saffron', child: Text('Saffron')),
              DropdownMenuItem(value: 'lotus', child: Text('Lotus Pink')),
              DropdownMenuItem(value: 'peacock', child: Text('Peacock Teal')),
              DropdownMenuItem(value: 'vrindavan', child: Text('Vrindavan Green')),
              DropdownMenuItem(value: 'indigo', child: Text('Krishna Indigo')),
            ],
            onChanged: (v) => sp.update(() => sp.counterColorKey = v ?? 'lotus'),
          ),

          const SizedBox(height: 12),
          _SwitchCard(
            title: "Hide minus button",
            subtitle: sp.hideMinusButton ? "Minus button is hidden" : "Minus button is showing",
            value: sp.hideMinusButton,
            onChanged: (v) => sp.update(() => sp.hideMinusButton = v),
            borderColor: border,
            cardBg: cardBg,
          ),

          const SizedBox(height: 12),
          _SwitchCard(
            title: "Regular haptic feedback",
            subtitle: sp.regularHaptic ? "Vibration on each button press" : "No vibration on key press",
            value: sp.regularHaptic,
            onChanged: (v) => sp.update(() => sp.regularHaptic = v),
            borderColor: border,
            cardBg: cardBg,
          ),

          const SizedBox(height: 12),
          _SwitchCard(
            title: "Long haptic feedback",
            subtitle: sp.longHaptic ? "Long vibration on cycle completion" : "Long vibration is OFF",
            value: sp.longHaptic,
            onChanged: (v) => sp.update(() => sp.longHaptic = v),
            borderColor: border,
            cardBg: cardBg,
          ),

          const SizedBox(height: 12),
          const _FieldLabel("Size of 1 cycle / mala"),
          TextFormField(
            initialValue: sp.cycleSize.toString(),
            keyboardType: TextInputType.number,
            decoration: _inputDec(border, cardBg),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 108;
              sp.update(() => sp.cycleSize = n < 1 ? 1 : n);
            },
          ),

          const SizedBox(height: 16),

          // only one reset button
          TextButton.icon(
            onPressed: () => sp.resetToDefaults(),
            icon: const Icon(Icons.restart_alt, color: Colors.red),
            label: const Text(
              "Reset to defaults",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDec(Color border, Color bg) {
    return InputDecoration(
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: border, width: 1.4),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: color, fontFamily: "CormorantGaramond"),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color borderColor;
  final Color cardBg;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.borderColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}