import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mantra_icon.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/streak.dart';
import '../widgets/app_ui.dart';
import '../widgets/counter_avatar.dart';
import '../widgets/counter_editor_sheet.dart';
import '../widgets/progress_ring.dart';
import 'counter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _askedForFirstCounter = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_askedForFirstCounter) return;
    _askedForFirstCounter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<CounterProvider>().counters.isEmpty) {
        _createCounter(first: true);
      }
    });
  }

  void _openDay(DateTime day) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CounterScreen(date: day)));
  }

  Future<void> _createCounter({bool first = false}) async {
    final cp = context.read<CounterProvider>();
    final sp = context.read<SettingsProvider>();
    final draft = await showCounterEditor(
      context,
      cycleSize: sp.cycleSize,
      suggestedColor: cp.nextColor(),
      title: first ? 'Create your first counter' : null,
    );
    if (draft == null) return;
    await cp.addCounter(
      draft.name,
      iconId: draft.iconId,
      color: draft.color,
      dailyGoalCycles: draft.dailyGoalCycles,
      customGlyph: draft.customGlyph,
    );
  }

  Future<void> _editCounter(CounterProfile counter) async {
    final cp = context.read<CounterProvider>();
    final draft = await showCounterEditor(
      context,
      cycleSize: context.read<SettingsProvider>().cycleSize,
      initial: counter,
    );
    if (draft == null) return;
    await cp.updateCounter(
      counter.id,
      name: draft.name,
      iconId: draft.iconId,
      color: draft.color,
      dailyGoalCycles: draft.dailyGoalCycles,
      customGlyph: draft.customGlyph,
    );
  }

  Future<void> _deleteCounter(CounterProfile counter) async {
    final cp = context.read<CounterProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${counter.name}?',
      message: 'All of its chanting history will be removed. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await cp.removeCounter(counter.id);
  }

  Future<void> _showCounterSwitcher() async {
    // Each action closes the sheet first, then runs on the Home context.
    final action = await showModalBottomSheet<(String, CounterProfile?)>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer2<CounterProvider, SettingsProvider>(
        builder: (ctx, cp, sp, _) {
          final todayKey = isoDate(today());
          return SheetScaffold(
            title: 'Your counters',
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                for (final c in cp.counters)
                  ListTile(
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                    contentPadding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.xs),
                    selected: c.id == cp.activeCounter?.id,
                    leading: CounterAvatar.of(c),
                    title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${c.countsByDate[todayKey] ?? 0} today, goal ${c.dailyGoalCycles} '
                      '${c.dailyGoalCycles == 1 ? 'mala' : 'malas'}',
                    ),
                    onTap: () async {
                      await cp.switchCounter(c.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.pop(ctx, ('edit', c)),
                        ),
                        IconButton(
                          tooltip: cp.counters.length > 1 ? 'Delete' : 'You need at least one counter',
                          icon: Icon(Icons.delete_outline_rounded),
                          onPressed: cp.counters.length > 1 ? () => Navigator.pop(ctx, ('delete', c)) : null,
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, ('add', null)),
                    icon: Icon(Icons.add_rounded),
                    label: const Text('New counter'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!mounted || action == null) return;
    final (kind, counter) = action;
    switch (kind) {
      case 'edit':
        await _editCounter(counter!);
      case 'delete':
        await _deleteCounter(counter!);
      case 'add':
        await _createCounter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final sp = context.watch<SettingsProvider>();
    final active = cp.activeCounter;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppPageHeader(
            title: 'Sadhana',
            leadingMark: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(width: 32, height: 32),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'New counter',
                onPressed: _createCounter,
                icon: Icon(Icons.add_rounded),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                if (active == null)
                  _EmptyState(onCreate: _createCounter)
                else
                  _TodayCard(
                    counter: active,
                    cycleSize: sp.cycleSize,
                    accent: sp.counterAccentColor,
                    streak: cp.streak(cycleSize: sp.cycleSize),
                    onSwitch: _showCounterSwitcher,
                    onOpen: () => _openDay(today()),
                    onEdit: () => _editCounter(active),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _CalendarCard(onOpenDay: _openDay),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Today

class _TodayCard extends StatelessWidget {
  final CounterProfile counter;
  final int cycleSize;
  final Color accent;
  final StreakInfo streak;
  final VoidCallback onSwitch;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _TodayCard({
    required this.counter,
    required this.cycleSize,
    required this.accent,
    required this.streak,
    required this.onSwitch,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final count = counter.countsByDate[isoDate(today())] ?? 0;
    final goal = counter.dailyGoalCycles;
    final goalChants = goal * cycleSize;
    final malas = count ~/ cycleSize;
    final reached = count >= goalChants;
    final atRisk = streak.current > 0 && !streak.doneToday;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onSwitch,
                    borderRadius: AppRadius.smAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              counter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.expand_more_rounded, size: 16, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StreakPill(streak: streak),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                GestureDetector(
                  onTap: onOpen,
                  child: ProgressRing(
                    progress: goalChants == 0 ? 0 : count / goalChants,
                    color: accent,
                    size: 104,
                    strokeWidth: 9,
                    child: Hero(
                      tag: CounterAvatar.heroTag(counter.id),
                      child: CounterAvatar.of(counter, size: 60),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reached ? 'Goal reached today' : 'Today\'s goal',
                        style: theme.textTheme.titleSmall?.copyWith(color: reached ? accent : scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$malas of $goal ${goal == 1 ? 'mala' : 'malas'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: AppFonts.sans,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reached ? '$count chants so far' : '${goalChants - count} chants to go',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (atRisk) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Finish one mala today to keep your ${streak.current}-day streak.',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(count == 0 ? 'Start chanting' : 'Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final StreakInfo streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    final n = streak.current;
    return Tooltip(
      message: 'Best streak: ${streak.best} ${streak.best == 1 ? 'day' : 'days'}',
      child: InfoPill(
        color: n > 0 ? const Color(0xFFF97316) : Theme.of(context).colorScheme.outline,
        leading: Text(n > 0 ? '🔥' : '🌱', style: const TextStyle(fontSize: 14, height: 1)),
        label: n > 0 ? '$n day streak' : 'No streak yet',
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CounterAvatar(icon: MantraIcons.byId(MantraIcons.fallbackId), color: theme.colorScheme.primary, size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text('Start with your first mantra', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a counter to track your daily jaap, set a goal, and build a streak.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add_rounded),
              label: const Text('Create counter'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Calendar

class _CalendarCard extends StatefulWidget {
  final ValueChanged<DateTime> onOpenDay;
  const _CalendarCard({required this.onOpenDay});

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  /// Any day inside the period on screen (a week or a month).
  DateTime _anchor = today();

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  bool _isCurrentPeriod(bool compact) {
    final now = today();
    return compact
        ? startOfWeek(_anchor) == startOfWeek(now)
        : _anchor.year == now.year && _anchor.month == now.month;
  }

  void _shift(bool compact, int direction) {
    setState(() {
      _anchor = compact
          ? addDays(_anchor, 7 * direction)
          : DateTime(_anchor.year, _anchor.month + direction, 1);
    });
  }

  void _toggle(SettingsProvider sp) {
    final toCompact = !sp.calendarCompact;
    final now = today();
    // Collapsing onto the current month should land on this week.
    if (toCompact && _anchor.year == now.year && _anchor.month == now.month) _anchor = now;
    sp.update(() => sp.calendarCompact = toCompact);
  }

  String _title(bool compact) {
    if (!compact) return DateFormat('MMMM yyyy').format(_anchor);
    final start = startOfWeek(_anchor);
    final end = addDays(start, 6);
    if (start.month == end.month) return DateFormat('MMMM yyyy').format(start);
    if (start.year == end.year) return '${DateFormat('MMM').format(start)} – ${DateFormat('MMM yyyy').format(end)}';
    return '${DateFormat('MMM yyyy').format(start)} – ${DateFormat('MMM yyyy').format(end)}';
  }

  List<DateTime?> _cells(bool compact) {
    if (compact) {
      final start = startOfWeek(_anchor);
      return [for (var i = 0; i < 7; i++) addDays(start, i)];
    }
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final daysInMonth = DateTime(_anchor.year, _anchor.month + 1, 0).day;
    final out = <DateTime?>[
      for (var i = 0; i < first.weekday % 7; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_anchor.year, _anchor.month, d),
    ];
    while (out.length % 7 != 0) {
      out.add(null);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = sp.calendarCompact;
    final cells = _cells(compact);
    final periodKey = compact ? isoDate(startOfWeek(_anchor)) : '${_anchor.year}-${_anchor.month}';
    final duration = AppMotion.of(context, AppMotion.medium);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: compact ? 'Show full month' : 'Show this week only',
                    child: InkWell(
                      onTap: () => _toggle(sp),
                      borderRadius: AppRadius.smAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _title(compact),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AnimatedRotation(
                              turns: compact ? 0 : 0.5,
                              duration: duration,
                              curve: AppMotion.standard,
                              child: Icon(Icons.expand_more_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: child)),
                  child: _isCurrentPeriod(compact)
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Go to today',
                          onPressed: () => setState(() => _anchor = today()),
                          icon: Icon(Icons.today_rounded),
                        ),
                ),
                IconButton(
                  tooltip: compact ? 'Previous week' : 'Previous month',
                  onPressed: () => _shift(compact, -1),
                  icon: Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: compact ? 'Next week' : 'Next month',
                  onPressed: () => _shift(compact, 1),
                  icon: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSize(
              duration: duration,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
                child: _DayGrid(
                  key: ValueKey('$compact-$periodKey'),
                  cells: cells,
                  onOpenDay: widget.onOpenDay,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final List<DateTime?> cells;
  final ValueChanged<DateTime> onOpenDay;

  const _DayGrid({super.key, required this.cells, required this.onOpenDay});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.78,
      children: [
        for (final d in cells) d == null ? const SizedBox.shrink() : _DayCell(day: d, onTap: () => onOpenDay(d)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = sp.counterAccentColor;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : Colors.black;

    final key = isoDate(day);
    final now = today();
    final isToday = day == now;
    final isFuture = day.isAfter(now);

    // One dot per counter that completed at least one mala (counter colour).
    final dots = <Color>[
      for (final c in cp.counters)
        if ((c.countsByDate[key] ?? 0) >= sp.cycleSize) c.color,
    ];

    final active = cp.activeCounter;
    final goalMet = active != null &&
        (active.countsByDate[key] ?? 0) >= active.dailyGoalCycles * sp.cycleSize;

    // Today: solid accent circle. Goal met: tinted circle with accent ring.
    final Color fill;
    final Color textColor;
    final BorderSide ring;
    if (isToday) {
      fill = accent;
      textColor = onAccent;
      ring = BorderSide.none;
    } else if (goalMet) {
      fill = accent.withValues(alpha: 0.16);
      textColor = scheme.onSurface;
      ring = BorderSide(color: accent, width: 1.5);
    } else {
      fill = Colors.transparent;
      textColor = isFuture ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : scheme.onSurface;
      ring = BorderSide.none;
    }

    return Semantics(
      button: true,
      label: '${DateFormat('EEEE d MMMM').format(day)}${goalMet ? ', goal reached' : ''}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = [constraints.maxWidth, constraints.maxHeight - 10, 40.0].reduce((a, b) => a < b ? a : b);
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: diameter,
                child: Material(
                  color: fill,
                  shape: CircleBorder(side: ring),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: AppFonts.sans,
                          fontWeight: isToday || goalMet ? FontWeight.w700 : FontWeight.w500,
                          color: textColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final color in dots.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    if (dots.length > 3)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: scheme.onSurfaceVariant, shape: BoxShape.circle),
                      ),
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