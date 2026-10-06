import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/app_ui.dart';
import '../widgets/counter_avatar.dart';

enum _Range { week, month }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _Range _range = _Range.week;

  /// null = all counters combined.
  String? _counterId;

  static final _number = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final sp = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final selected = _counterId == null ? null : cp.byId(_counterId!);
    final counterId = selected?.id; // falls back to "all" if it was deleted
    final accent = sp.counterAccentColor;
    final cycle = sp.cycleSize;

    final days = lastNDays(_range == _Range.week ? 7 : 30);
    final values = [for (final d in days) cp.chantsOn(d, counterId: counterId)];
    final total = values.fold<int>(0, (a, b) => a + b);

    var malas = 0;
    for (final d in days) {
      final key = isoDate(d);
      for (final c in selected == null ? cp.counters : [selected]) {
        malas += (c.countsByDate[key] ?? 0) ~/ cycle;
      }
    }

    var bestIndex = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[bestIndex]) bestIndex = i;
    }
    final hasData = total > 0;
    final average = total / days.length;
    final goalChants = selected == null ? null : (selected.dailyGoalCycles * cycle).toDouble();
    final streak = cp.streak(cycleSize: cycle, counterId: counterId, allCounters: counterId == null);
    final rangeLabel = _range == _Range.week ? '7 days' : '30 days';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppPageHeader(title: 'Statistics'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
            sliver: SliverList.list(
              children: cp.counters.isEmpty
                  ? [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'Create a counter on the Home tab to see your progress here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ]
                  : [
                      _CounterFilter(
                        counters: cp.counters,
                        selectedId: counterId,
                        onSelected: (id) => setState(() => _counterId = id),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<_Range>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: _Range.week, label: Text('7 days')),
                            ButtonSegment(value: _Range.month, label: Text('30 days')),
                          ],
                          selected: {_range},
                          onSelectionChanged: (s) => setState(() => _range = s.first),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chants per day', style: theme.textTheme.titleLarge),
                              Text(
                                '${_number.format(total)} chants in the last $rangeLabel',
                                style: _numeric(theme.textTheme.bodySmall),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                height: 220,
                                child: AnimatedSwitcher(
                                  duration: AppMotion.of(context, AppMotion.medium),
                                  switchInCurve: AppMotion.enter,
                                  switchOutCurve: AppMotion.exit,
                                  transitionBuilder: (child, a) => FadeTransition(
                                    opacity: a,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.97, end: 1).animate(a),
                                      child: child,
                                    ),
                                  ),
                                  child: !hasData
                                      ? _EmptyChart(key: const ValueKey('empty'), rangeLabel: rangeLabel)
                                      : _range == _Range.week
                                          ? _WeekBars(
                                              key: const ValueKey('week'),
                                              days: days,
                                              values: values,
                                              color: accent,
                                              goal: goalChants,
                                            )
                                          : _MonthLine(
                                              key: const ValueKey('month'),
                                              days: days,
                                              values: values,
                                              color: accent,
                                              goal: goalChants,
                                            ),
                                ),
                              ),
                              if (goalChants != null && hasData) ...[
                                const SizedBox(height: AppSpacing.md),
                                _GoalLegend(label: 'Daily goal: ${_number.format(goalChants)} chants'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _StatTile(label: 'Total chants', value: _number.format(total))),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _StatTile(label: 'Malas completed', value: _number.format(malas))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(label: 'Daily average', value: _number.format(average.round())),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatTile(
                              label: 'Best day',
                              value: hasData ? _number.format(values[bestIndex]) : '–',
                              caption: hasData ? DateFormat('EEE, d MMM').format(days[bestIndex]) : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Current streak',
                              value: '${streak.current} ${streak.current == 1 ? 'day' : 'days'}',
                              leading: '🔥',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatTile(
                              label: 'Best streak',
                              value: '${streak.best} ${streak.best == 1 ? 'day' : 'days'}',
                              leading: '🏆',
                            ),
                          ),
                        ],
                      ),
                      if (selected == null && cp.counters.length > 1) ...[
                        const SizedBox(height: AppSpacing.xl),
                        SectionHeader('By counter, last $rangeLabel'),
                        _Breakdown(counters: cp.counters, days: days, total: total),
                      ],
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterFilter extends StatelessWidget {
  final List<CounterProfile> counters;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _CounterFilter({required this.counters, required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All counters'),
            selected: selectedId == null,
            showCheckmark: false,
            onSelected: (_) => onSelected(null),
          ),
          for (final c in counters) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              avatar: CounterAvatar.of(c, size: 24),
              label: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: selectedId == c.id,
              showCheckmark: false,
              onSelected: (_) => onSelected(c.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final String? leading;

  const _StatTile({required this.label, required this.value, this.caption, this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                leading == null ? value : '$leading $value',
                style: _numeric(theme.textTheme.headlineMedium)?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
            Text(caption ?? ' ', style: _numeric(theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class _GoalLegend extends StatelessWidget {
  final String label;
  const _GoalLegend({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 6,
            height: 2,
            margin: const EdgeInsets.only(right: 3),
            color: theme.colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String rangeLabel;
  const _EmptyChart({super.key, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No chants in the last $rangeLabel yet.\nOpen a counter from Home to begin.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// --- Charts --------------------------------------------------------------------

/// Inter with tabular (equal-width) digits for every number on this screen.
TextStyle? _numeric(TextStyle? base) => base?.copyWith(
      fontFamily: AppFonts.sans,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

double _maxY(List<int> values, double? goal) {
  var m = 0.0;
  for (final v in values) {
    if (v > m) m = v.toDouble();
  }
  if (goal != null && goal > m) m = goal;
  return m <= 0 ? 1 : m * 1.2;
}

TextStyle _tooltipStyle(ColorScheme scheme) =>
    TextStyle(
      color: scheme.onInverseSurface,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      fontFamily: AppFonts.sans,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

final _tooltipNumber = NumberFormat.decimalPattern();

ExtraLinesData _goalLine(double? goal, ColorScheme scheme) => ExtraLinesData(
      horizontalLines: [
        if (goal != null)
          HorizontalLine(y: goal, color: scheme.onSurfaceVariant, strokeWidth: 1.2, dashArray: const [6, 4]),
      ],
    );

class _WeekBars extends StatelessWidget {
  final List<DateTime> days;
  final List<int> values;
  final Color color;
  final double? goal;

  const _WeekBars({super.key, required this.days, required this.values, required this.color, this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxY = _maxY(values, goal);
    final todayIndex = days.length - 1;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        extraLinesData: _goalLine(goal, scheme),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    DateFormat.E().format(days[i]),
                    style: _numeric(theme.textTheme.labelSmall)?.copyWith(
                      color: i == todayIndex ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: i == todayIndex ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: AppRadius.smAll,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${DateFormat('EEE, d MMM').format(days[group.x])}\n${_tooltipNumber.format(rod.toY.round())} chants',
              _tooltipStyle(scheme),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 18,
                  color: i == todayIndex ? color : color.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.standard,
    );
  }
}

class _MonthLine extends StatelessWidget {
  final List<DateTime> days;
  final List<int> values;
  final Color color;
  final double? goal;

  const _MonthLine({super.key, required this.days, required this.values, required this.color, this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxY = _maxY(values, goal);
    final last = days.length - 1;
    final compact = NumberFormat.compact();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: last.toDouble(),
        minY: 0,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        extraLinesData: _goalLine(goal, scheme),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1, dashArray: const [4, 4]),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    compact.format(value),
                    textAlign: TextAlign.right,
                    style: _numeric(theme.textTheme.labelSmall)?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                // Today, and every 7 days back from it.
                if (value != i || i < 0 || i > last || (last - i) % 7 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    DateFormat('d MMM').format(days[i]),
                    style: _numeric(theme.textTheme.labelSmall)?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: AppRadius.smAll,
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${DateFormat('EEE, d MMM').format(days[s.x.toInt()])}\n${_tooltipNumber.format(s.y.round())} chants',
                  _tooltipStyle(scheme),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].toDouble())],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.standard,
    );
  }
}

class _Breakdown extends StatelessWidget {
  final List<CounterProfile> counters;
  final List<DateTime> days;
  final int total;

  const _Breakdown({required this.counters, required this.days, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat.decimalPattern();
    final rows = [
      for (final c in counters)
        (c, days.fold<int>(0, (sum, d) => sum + (c.countsByDate[isoDate(d)] ?? 0))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return CardGroup(
      children: [
        for (final (counter, chants) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                CounterAvatar.of(counter),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              counter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(number.format(chants), style: _numeric(theme.textTheme.labelLarge)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(3)),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : chants / total,
                          minHeight: 6,
                          color: counter.color,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}