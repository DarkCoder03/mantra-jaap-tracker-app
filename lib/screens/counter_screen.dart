import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import '../services/volume_key_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/app_ui.dart';
import '../widgets/counter_avatar.dart';

class CounterScreen extends StatefulWidget {
  final DateTime date;
  const CounterScreen({super.key, required this.date});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final SettingsProvider _settings;
  StreamSubscription<VolumeKey>? _volumeSub;
  bool _wakeLockOn = false;
  bool? _hasVibrator;

  String get _iso => isoDate(widget.date);
  bool get _isToday => isSameDay(widget.date, DateTime.now());

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsProvider>();
    _settings.addListener(_syncHardware);
    _syncHardware();
  }

  @override
  void dispose() {
    _settings.removeListener(_syncHardware);
    _volumeSub?.cancel();
    if (_wakeLockOn) WakelockPlus.disable();
    _glow.dispose();
    super.dispose();
  }

  /// Applies "keep screen on" and "volume button counting" live, so toggling
  /// them from the options sheet takes effect immediately.
  void _syncHardware() {
    final wantWake = _settings.keepScreenOn;
    if (wantWake != _wakeLockOn) {
      _wakeLockOn = wantWake;
      WakelockPlus.toggle(enable: wantWake);
    }

    final wantVolume = _settings.volumeKeyCounting && VolumeKeyService.isSupported;
    if (wantVolume && _volumeSub == null) {
      _volumeSub = VolumeKeyService.events.listen(_onVolumeKey);
    } else if (!wantVolume && _volumeSub != null) {
      _volumeSub!.cancel();
      _volumeSub = null;
    }
  }

  void _onVolumeKey(VolumeKey key) {
    // Ignore presses while a sheet or dialog is open on top of the counter.
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    key == VolumeKey.up ? _increment() : _decrement();
  }

  Future<void> _vibrate({int? duration, List<int>? pattern}) async {
    _hasVibrator ??= await Vibration.hasVibrator();
    if (_hasVibrator != true) return;
    if (pattern != null) {
      Vibration.vibrate(pattern: pattern);
    } else {
      Vibration.vibrate(duration: duration ?? 12);
    }
  }

  Future<void> _increment() async {
    final cp = context.read<CounterProvider>();
    final counter = cp.activeCounter;
    if (counter == null) return;

    final after = cp.countForDate(_iso) + 1;
    await cp.increment(_iso);

    if (_settings.regularHaptic) _vibrate(duration: 12);

    if (after % _settings.cycleSize != 0) return;

    // A mala was just completed.
    _glow.forward(from: 0);
    if (_settings.soundAlert) SoundService().playByType(_settings.soundType);
    if (_settings.longHaptic) _vibrate(pattern: [0, 65, 35, 110]);

    final malas = after ~/ _settings.cycleSize;
    if (mounted && malas == counter.dailyGoalCycles) {
      showAppSnackBar(
        context,
        _isToday
            ? 'Daily goal reached: $malas ${malas == 1 ? 'mala' : 'malas'} today.'
            : 'Goal reached for this day.',
      );
    }
  }

  Future<void> _decrement() async {
    await context.read<CounterProvider>().decrement(_iso);
    if (_settings.regularHaptic) _vibrate(duration: 8);
  }

  Future<void> _confirmReset(String counterName, String dayLabel) async {
    final cp = context.read<CounterProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Reset this day?',
      message: '$counterName on $dayLabel goes back to zero.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (ok) await cp.resetDay(_iso);
  }

  Future<void> _openOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer<SettingsProvider>(
        builder: (ctx, sp, _) => SheetScaffold(
          title: 'Counter options',
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                secondary: const Icon(Icons.remove_rounded),
                title: const Text('Show minus button'),
                subtitle: Text(sp.hideMinusButton ? 'Tap anywhere on the screen to count' : 'Shown next to the plus button'),
                value: !sp.hideMinusButton,
                onChanged: (v) => sp.update(() => sp.hideMinusButton = !v),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Count with volume buttons'),
                subtitle: Text(VolumeKeyService.isSupported ? 'Up adds one, down removes one' : 'Available on Android'),
                value: sp.volumeKeyCounting && VolumeKeyService.isSupported,
                onChanged: VolumeKeyService.isSupported ? (v) => sp.update(() => sp.volumeKeyCounting = v) : null,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                secondary: const Icon(Icons.light_mode_outlined),
                title: const Text('Keep screen on'),
                subtitle: const Text('While this screen is open'),
                value: sp.keepScreenOn,
                onChanged: (v) => sp.update(() => sp.keepScreenOn = v),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Button colour'),
                subtitle: Text(SettingsProvider.labelFor(SettingsProvider.counterColorOptions, sp.counterColorKey)),
                trailing: ColorDot(sp.counterAccentColor),
                onTap: () async {
                  final v = await showChoiceSheet(
                    ctx,
                    title: 'Button colour',
                    options: SettingsProvider.counterColorOptions,
                    selected: sp.counterColorKey,
                  );
                  if (v != null) sp.update(() => sp.counterColorKey = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counter = cp.activeCounter;
    final dayLabel = _isToday ? 'today' : DateFormat('EEE, d MMM y').format(widget.date);

    if (counter == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Create a counter on the Home tab first.')),
      );
    }

    final accent = sp.counterAccentColor;
    final count = cp.countForDate(_iso);
    final inCycle = count % sp.cycleSize;
    final malas = count ~/ sp.cycleSize;
    final goal = counter.dailyGoalCycles;
    final showMinus = !sp.hideMinusButton;
    final volumeActive = sp.volumeKeyCounting && VolumeKeyService.isSupported;
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // v1 layout: info and the big number in the middle, buttons below.
    final center = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateFormat('EEEE, d MMM y').format(widget.date), style: hint),
        const SizedBox(height: 2),
        Text('Total: $count', style: hint),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: CounterAvatar.heroTag(counter.id),
              child: CounterAvatar.of(counter, size: 44),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                counter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displayMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Mala, completed and goal together; the goal lights up once reached.
        Text.rich(
          TextSpan(
            style: hint,
            children: [
              TextSpan(text: 'Mala: $inCycle / ${sp.cycleSize}  •  Completed: $malas  •  '),
              TextSpan(
                text: 'Goal: $goal',
                style: malas >= goal ? TextStyle(color: accent, fontWeight: FontWeight.w600) : null,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(a),
                child: child,
              ),
            ),
            child: Text(
              '$inCycle',
              key: ValueKey(count),
              style: const TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 132,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _CompletionGlow(animation: _glow, color: accent)),
          SafeArea(
            child: Column(
              children: [
                // Top bar (v1 style): Back on the left, options and Reset on the right.
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back'),
                      ),
                      const Spacer(),
                      IconButton.outlined(
                        tooltip: 'Counter options',
                        onPressed: _openOptions,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.tonal(
                        onPressed: () => _confirmReset(counter.name, dayLabel),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                // With the minus button hidden, the whole middle area counts on tap.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: showMinus ? null : _increment,
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      // Shrinks to fit on short screens instead of overflowing.
                      child: LayoutBuilder(
                        builder: (context, constraints) => Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(width: constraints.maxWidth, child: center),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Three equal slots keep the + button exactly centred,
                // whether or not the minus button is shown.
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: showMinus
                            ? _RoundAction(
                                size: 68,
                                color: sp.counterAccentDeep,
                                icon: Icons.remove_rounded,
                                semanticLabel: 'Remove one',
                                onTap: _decrement,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    _RoundAction(
                      size: showMinus ? 150 : 168,
                      color: accent,
                      icon: Icons.add_rounded,
                      semanticLabel: 'Add one',
                      elevation: 8,
                      onTap: _increment,
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 20,
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: Text(
                      volumeActive
                          ? 'Volume buttons are counting'
                          : (showMinus ? '' : 'Tap anywhere to count'),
                      key: ValueKey('$volumeActive-$showMinus'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft radial bloom after each completed mala.
class _CompletionGlow extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _CompletionGlow({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, _) {
          final v = animation.value;
          if (v == 0 || v == 1) return const SizedBox.shrink();
          final t = Curves.easeOutCubic.transform(v);
          final opacity = (1 - t) * 0.38;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.05),
                radius: 0.9 + t * 0.45,
                colors: [
                  color.withValues(alpha: opacity),
                  color.withValues(alpha: opacity * 0.16),
                  Colors.transparent,
                ],
                stops: const [0, .58, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundAction extends StatefulWidget {
  final double size;
  final Color color;
  final IconData icon;
  final String semanticLabel;
  final double elevation;
  final VoidCallback onTap;

  const _RoundAction({
    required this.size,
    required this.color,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.elevation = 2,
  });

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(widget.color) == Brightness.dark ? Colors.white : Colors.black;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 80),
        child: Material(
          color: widget.color,
          elevation: widget.elevation,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _set(true),
            onTapUp: (_) => _set(false),
            onTapCancel: () => _set(false),
            child: SizedBox.square(
              dimension: widget.size,
              child: Icon(widget.icon, size: widget.size * 0.42, color: onColor),
            ),
          ),
        ),
      ),
    );
  }
}