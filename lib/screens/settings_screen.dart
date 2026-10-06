import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/sound_service.dart';
import '../services/volume_key_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import '../widgets/app_ui.dart';

/// Performance notes:
/// - The whole list is a compile-time constant, so it is built once and never
///   rebuilt when the parent rebuilds.
/// - The screen itself does not listen to [SettingsProvider]. Each row uses
///   `context.select` on its own value, so toggling one switch rebuilds only
///   that row instead of all of them.
/// - The list is laid out by a sliver, and every card gets its own repaint
///   boundary from the sliver delegate.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Widget> _sections = [
    SectionHeader('Appearance'),
    CardGroup(
      children: [
        _ChoiceSetting<AppThemeMode>(
          icon: Icons.contrast_rounded,
          title: 'Theme',
          options: SettingsProvider.themeModeOptions,
          read: _S.theme,
          write: _S.setTheme,
        ),
        _ChoiceSetting<String>(
          icon: Icons.palette_outlined,
          title: 'Accent colour',
          options: SettingsProvider.primaryThemeOptions,
          read: _S.accent,
          write: _S.setAccent,
          showSwatch: true,
        ),
        _ChoiceSetting<String>(
          icon: Icons.touch_app_outlined,
          title: 'Counter button colour',
          options: SettingsProvider.counterColorOptions,
          read: _S.buttonColour,
          write: _S.setButtonColour,
          showSwatch: true,
        ),
      ],
    ),
    SizedBox(height: AppSpacing.xl),
    SectionHeader('Counting'),
    CardGroup(
      children: [
        _BeadsSetting(),
        _SwitchSetting(
          icon: Icons.remove_rounded,
          title: 'Show minus button',
          subtitleOn: 'Shown next to the plus button',
          subtitleOff: 'Hidden: tap anywhere to count',
          read: _S.showMinus,
          write: _S.setShowMinus,
        ),
        _VolumeSetting(),
        _SwitchSetting(
          icon: Icons.light_mode_outlined,
          title: 'Keep screen on',
          subtitleOn: 'While the counter is open',
          subtitleOff: 'While the counter is open',
          read: _S.keepScreenOn,
          write: _S.setKeepScreenOn,
        ),
      ],
    ),
    SizedBox(height: AppSpacing.xl),
    SectionHeader('Sound and vibration'),
    CardGroup(
      children: [
        _SwitchSetting(
          icon: Icons.notifications_outlined,
          title: 'Sound after each mala',
          read: _S.soundAlert,
          write: _S.setSoundAlert,
        ),
        _SoundSetting(),
        _SwitchSetting(
          icon: Icons.vibration_rounded,
          title: 'Vibrate on each count',
          read: _S.tapHaptic,
          write: _S.setTapHaptic,
        ),
        _SwitchSetting(
          icon: Icons.auto_awesome_outlined,
          title: 'Long vibration after each mala',
          read: _S.longHaptic,
          write: _S.setLongHaptic,
        ),
      ],
    ),
    SizedBox(height: AppSpacing.xl),
    SectionHeader('Your data'),
    CardGroup(
      children: [
        _ActionSetting(
          icon: Icons.save_outlined,
          title: 'Back up',
          subtitle: 'Save counters and settings to a file',
          onTap: _S.backup,
        ),
        _ActionSetting(
          icon: Icons.settings_backup_restore_rounded,
          title: 'Restore',
          subtitle: 'Replace current data with a backup file',
          onTap: _S.restore,
        ),
      ],
    ),
    SizedBox(height: AppSpacing.xl),
    SectionHeader('About'),
    CardGroup(
      children: [
        _ActionSetting(
          icon: Icons.spa_outlined,
          title: 'Show the introduction again',
          onTap: _S.showIntro,
        ),
        _ActionSetting(
          icon: Icons.star_outline_rounded,
          title: 'Rate the app',
          onTap: _S.rate,
        ),
        _ActionSetting(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'Version $kAppVersion',
          onTap: _S.about,
        ),
      ],
    ),
    SizedBox(height: AppSpacing.xl),
    _ResetButton(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppPageHeader(title: 'Settings'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xxl),
            sliver: SliverList.list(children: _sections),
          ),
        ],
      ),
    );
  }
}

// --- Row types ------------------------------------------------------------------

class _SwitchSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitleOn;
  final String? subtitleOff;
  final bool Function(SettingsProvider) read;
  final void Function(SettingsProvider, bool) write;

  const _SwitchSetting({
    required this.icon,
    required this.title,
    required this.read,
    required this.write,
    this.subtitleOn,
    this.subtitleOff,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.select<SettingsProvider, bool>(read);
    final subtitle = value ? subtitleOn : subtitleOff;
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: (v) {
        final s = context.read<SettingsProvider>();
        s.update(() => write(s, v));
      },
    );
  }
}

class _ChoiceSetting<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<SettingOption<T>> options;
  final T Function(SettingsProvider) read;
  final void Function(SettingsProvider, T) write;
  final bool showSwatch;

  const _ChoiceSetting({
    required this.icon,
    required this.title,
    required this.options,
    required this.read,
    required this.write,
    this.showSwatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.select<SettingsProvider, T>(read);
    final option = options.firstWhere((o) => o.value == value, orElse: () => options.first);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(option.label),
      trailing: _Trailing(swatch: showSwatch ? option.color : null),
      onTap: () async {
        final picked = await showChoiceSheet<T>(context, title: title, options: options, selected: value);
        if (picked == null || !context.mounted) return;
        final s = context.read<SettingsProvider>();
        s.update(() => write(s, picked));
      },
    );
  }
}

class _ActionSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final void Function(BuildContext) onTap;

  const _ActionSetting({required this.icon, required this.title, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () => onTap(context),
    );
  }
}

class _Trailing extends StatelessWidget {
  final Color? swatch;
  const _Trailing({this.swatch});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (swatch != null) ...[ColorDot(swatch!), const SizedBox(width: AppSpacing.sm)],
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    );
  }
}

class _BeadsSetting extends StatelessWidget {
  const _BeadsSetting();

  @override
  Widget build(BuildContext context) {
    final beads = context.select<SettingsProvider, int>((s) => s.cycleSize);
    return ListTile(
      leading: const Icon(Icons.donut_large_rounded),
      title: const Text('Beads per mala'),
      subtitle: Text('$beads'),
      trailing: const _Trailing(),
      onTap: () async {
        final text = await showTextInputDialog(
          context,
          title: 'Beads per mala',
          hint: '108',
          initial: '$beads',
          numeric: true,
        );
        final n = int.tryParse(text ?? '');
        if (n == null || n < 1 || !context.mounted) return;
        final s = context.read<SettingsProvider>();
        s.update(() => s.cycleSize = n.clamp(1, 100000));
      },
    );
  }
}

class _VolumeSetting extends StatelessWidget {
  const _VolumeSetting();

  @override
  Widget build(BuildContext context) {
    final supported = VolumeKeyService.isSupported;
    final on = context.select<SettingsProvider, bool>((s) => s.volumeKeyCounting);
    return SwitchListTile(
      secondary: const Icon(Icons.volume_up_outlined),
      title: const Text('Count with volume buttons'),
      subtitle: Text(supported ? 'Volume up adds one, volume down removes one' : 'Available on Android'),
      value: on && supported,
      onChanged: supported
          ? (v) {
              final s = context.read<SettingsProvider>();
              s.update(() => s.volumeKeyCounting = v);
            }
          : null,
    );
  }
}

class _SoundSetting extends StatelessWidget {
  const _SoundSetting();

  @override
  Widget build(BuildContext context) {
    final (enabled, type) = context.select<SettingsProvider, (bool, String)>((s) => (s.soundAlert, s.soundType));
    return ListTile(
      enabled: enabled,
      leading: const Icon(Icons.music_note_outlined),
      title: const Text('Sound'),
      subtitle: Text(SettingsProvider.labelFor(SettingsProvider.soundOptions, type)),
      trailing: const _Trailing(),
      onTap: () async {
        final picked = await showChoiceSheet<String>(
          context,
          title: 'Sound',
          options: SettingsProvider.soundOptions,
          selected: type,
        );
        if (picked == null || !context.mounted) return;
        final s = context.read<SettingsProvider>();
        s.update(() => s.soundType = picked);
        SoundService().playByType(picked);
      },
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        onPressed: () async {
          final ok = await showConfirmDialog(
            context,
            title: 'Reset settings?',
            message: 'Theme, sound, haptics and counting options go back to their defaults. Your counters and history are kept.',
            confirmLabel: 'Reset',
            destructive: true,
          );
          if (ok && context.mounted) await context.read<SettingsProvider>().resetToDefaults();
        },
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Reset settings to defaults'),
      ),
    );
  }
}

// --- Static readers, writers and actions (const-friendly tear-offs) ------------

abstract final class _S {
  static AppThemeMode theme(SettingsProvider s) => s.themeMode;
  static void setTheme(SettingsProvider s, AppThemeMode v) => s.themeMode = v;

  static String accent(SettingsProvider s) => s.primaryThemeKey;
  static void setAccent(SettingsProvider s, String v) => s.primaryThemeKey = v;

  static String buttonColour(SettingsProvider s) => s.counterColorKey;
  static void setButtonColour(SettingsProvider s, String v) => s.counterColorKey = v;

  static bool showMinus(SettingsProvider s) => !s.hideMinusButton;
  static void setShowMinus(SettingsProvider s, bool v) => s.hideMinusButton = !v;

  static bool keepScreenOn(SettingsProvider s) => s.keepScreenOn;
  static void setKeepScreenOn(SettingsProvider s, bool v) => s.keepScreenOn = v;

  static bool soundAlert(SettingsProvider s) => s.soundAlert;
  static void setSoundAlert(SettingsProvider s, bool v) => s.soundAlert = v;

  static bool tapHaptic(SettingsProvider s) => s.regularHaptic;
  static void setTapHaptic(SettingsProvider s, bool v) => s.regularHaptic = v;

  static bool longHaptic(SettingsProvider s) => s.longHaptic;
  static void setLongHaptic(SettingsProvider s, bool v) => s.longHaptic = v;

  static Future<void> backup(BuildContext context) async {
    final path = await BackupService().exportBackup(
      counters: context.read<CounterProvider>(),
      settings: context.read<SettingsProvider>(),
    );
    if (context.mounted) showAppSnackBar(context, 'Backup saved to $path');
  }

  static Future<void> restore(BuildContext context) async {
    final cp = context.read<CounterProvider>();
    final sp = context.read<SettingsProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Restore a backup?',
      message: 'Your current counters and settings will be replaced by the ones in the backup file.',
      confirmLabel: 'Choose file',
    );
    if (!ok) return;

    const invalid = 'That file isn\'t a valid backup. Choose a .json file exported from this app.';
    final Map<String, dynamic>? data;
    try {
      data = await BackupService().pickAndReadBackup();
    } catch (_) {
      if (context.mounted) showAppSnackBar(context, invalid);
      return;
    }
    if (data == null) return;

    final store = data['store'];
    final settings = data['settings'];
    if (store is! Map || settings is! Map) {
      if (context.mounted) showAppSnackBar(context, invalid);
      return;
    }
    await cp.importFromMap(Map<String, dynamic>.from(store));
    await sp.importFromMap(Map<String, dynamic>.from(settings));
    if (context.mounted) showAppSnackBar(context, 'Backup restored');
  }

  static void showIntro(BuildContext context) {
    final s = context.read<SettingsProvider>();
    s.update(() => s.onboardingDone = false);
  }

  static void rate(BuildContext context) => showAppSnackBar(context, 'Thanks for rating us ⭐');

  static void about(BuildContext context) => showAboutDialog(
        context: context,
        applicationName: kAppName,
        applicationVersion: kAppVersion,
        applicationIcon: ClipRRect(
          borderRadius: AppRadius.smAll,
          child: Image.asset('assets/logo.png', width: 48, height: 48),
        ),
      );
}