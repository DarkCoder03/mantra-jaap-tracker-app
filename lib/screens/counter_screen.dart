import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';

class CounterScreen extends StatefulWidget {
  final DateTime date;
  const CounterScreen({super.key, required this.date});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  bool _plusPressed = false;
  bool _showGlow = false;
  bool _showMinusButton = true;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _glowCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showGlow = false);
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sp = context.read<SettingsProvider>();
    _showMinusButton = !sp.hideMinusButton;
  }

  String get iso => DateFormat('yyyy-MM-dd').format(widget.date);

  Color _plusColor(String key) {
    switch (key) {
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

  Color _minusColor(String key) {
    switch (key) {
      case 'amber':
        return const Color(0xFFB45309);
      case 'saffron':
        return const Color(0xFFC2410C);
      case 'lotus':
        return const Color(0xFFBE185D);
      case 'peacock':
        return const Color(0xFF0F766E);
      case 'vrindavan':
        return const Color(0xFF047857);
      case 'indigo':
        return const Color(0xFF4338CA);
      default:
        return const Color(0xFFBE185D);
    }
  }

  Future<void> _increment(CounterProvider cp, SettingsProvider sp) async {
    final before = cp.countForDate(iso);
    await cp.increment(iso);
    final after = cp.countForDate(iso);

    if (sp.regularHaptic) {
      final has = await Vibration.hasVibrator() ?? false;
      if (has) Vibration.vibrate(duration: 12);
    }

    final completedNow = (after % sp.cycleSize == 0) && (after != before);
    if (completedNow) {
      if (mounted) setState(() => _showGlow = true);
      _glowCtrl.forward(from: 0);

      if (sp.soundAlert) await SoundService().playByType(sp.soundType);

      if (sp.longHaptic) {
        final has = await Vibration.hasVibrator() ?? false;
        if (has) Vibration.vibrate(pattern: [0, 65, 35, 110]);
      }
    }
  }

  Future<void> _openUnifiedGearMenu(SettingsProvider sp) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            return ListView(
              shrinkWrap: true,
              children: [
                SwitchListTile(
                  title: const Text("Show minus button"),
                  value: _showMinusButton,
                  onChanged: (v) async {
                    setState(() => _showMinusButton = v);
                    await sp.update(() => sp.hideMinusButton = !v);
                    setSheet(() {});
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("Counter colour"),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sp.counterColorKey,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onChanged: (v) async {
                        if (v == null) return;
                        await sp.update(() => sp.counterColorKey = v);
                        setSheet(() {});
                        if (mounted) setState(() {});
                      },
                      items: const [
                        DropdownMenuItem(value: 'amber', child: Text('Kesari (Amber)')),
                        DropdownMenuItem(value: 'saffron', child: Text('Saffron')),
                        DropdownMenuItem(value: 'lotus', child: Text('Lotus Pink')),
                        DropdownMenuItem(value: 'peacock', child: Text('Peacock Teal')),
                        DropdownMenuItem(value: 'vrindavan', child: Text('Vrindavan Green')),
                        DropdownMenuItem(value: 'indigo', child: Text('Krishna Indigo')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final sp = context.watch<SettingsProvider>();

    final extShowMinus = !sp.hideMinusButton;
    if (extShowMinus != _showMinusButton) _showMinusButton = extShowMinus;

    final count = cp.countForDate(iso);
    final cycleProgress = count % sp.cycleSize;
    final completed = count ~/ sp.cycleSize;
    final plus = _plusColor(sp.counterColorKey);
    final minus = _minusColor(sp.counterColorKey);
    final dateLabel = DateFormat('EEEE, MMM d, y').format(widget.date);

    final coreCenter = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(dateLabel, style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor)),
        const SizedBox(height: 2),
        Text("Total: $count", style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor)),
        const SizedBox(height: 12),
        Text(
          cp.activeCounter?.name ?? "-",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: "CormorantGaramond", fontSize: 52, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text("Cycle: $cycleProgress / ${sp.cycleSize} • Completed: $completed",
            style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor)),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: Text(
            "$cycleProgress",
            key: ValueKey(cycleProgress),
            style: const TextStyle(fontFamily: "Inter", fontSize: 102, fontWeight: FontWeight.w400, height: 0.95),
          ),
        ),
        const SizedBox(height: 24),
        if (_showMinusButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundAction(size: 72, color: minus, text: "−", textSize: 38, onTap: () => cp.decrement(iso)),
              const SizedBox(width: 16),
              AnimatedScale(
                scale: _plusPressed ? .96 : 1,
                duration: const Duration(milliseconds: 70),
                child: _RoundAction(
                  size: 134,
                  color: plus,
                  text: "+",
                  textSize: 56,
                  shadow: 10,
                  onTap: () async {
                    setState(() => _plusPressed = true);
                    await _increment(cp, sp);
                    await Future.delayed(const Duration(milliseconds: 60));
                    if (mounted) setState(() => _plusPressed = false);
                  },
                ),
              ),
            ],
          )
        else
          AnimatedScale(
            scale: _plusPressed ? .96 : 1,
            duration: const Duration(milliseconds: 70),
            child: _RoundAction(
              size: 160,
              color: plus,
              text: "+",
              textSize: 62,
              shadow: 12,
              onTap: () async {
                setState(() => _plusPressed = true);
                await _increment(cp, sp);
                await Future.delayed(const Duration(milliseconds: 60));
                if (mounted) setState(() => _plusPressed = false);
              },
            ),
          ),
      ],
    );

    Widget centerArea = Expanded(child: Center(child: coreCenter));

    if (!_showMinusButton) {
      centerArea = Expanded(
        child: Stack(
          children: [
            Center(child: coreCenter),
            Positioned.fill(
              top: MediaQuery.of(context).size.height * 0.5,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async => _increment(cp, sp),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_glowCtrl.value);
          final op = (1 - t) * 0.38;
          final r = 0.90 + (t * 0.45);

          return Stack(
            children: [
              if (_showGlow)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.05),
                        radius: r,
                        colors: [plus.withOpacity(op), plus.withOpacity(op * 0.16), Colors.transparent],
                        stops: const [0, .58, 1],
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("← Back")),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _openUnifiedGearMenu(sp),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(onPressed: () => cp.resetDay(iso), child: const Text("Reset")),
                        ],
                      ),
                    ),
                    centerArea,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final double size;
  final Color color;
  final String text;
  final double textSize;
  final double shadow;
  final VoidCallback onTap;

  const _RoundAction({
    required this.size,
    required this.color,
    required this.text,
    required this.textSize,
    this.shadow = 10,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: shadow,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(text, style: TextStyle(fontSize: textSize, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}