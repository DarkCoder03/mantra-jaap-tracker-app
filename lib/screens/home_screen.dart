import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/counter_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import 'counter_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _asked = false;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final GlobalKey _menuAnchorKey = GlobalKey();

  static const _dotPalette = [
    Color(0xFF14B8A6),
    Color(0xFFA855F7),
    Color(0xFFF43F5E),
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFF84CC16),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cp = context.read<CounterProvider>();
      if (cp.counters.isEmpty) {
        final name = await _askText("Create your first counter", hint: "Counter name");
        if (name != null && name.trim().isNotEmpty) {
          await cp.ensureFirstCounter(name.trim());
          if (mounted) setState(() {});
        }
      }
    });
  }

  Future<String?> _askText(String title, {String hint = "Enter text", String initial = ""}) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Save")),
        ],
      ),
    );
  }

  List<DateTime?> _monthCells(DateTime m) {
    final first = DateTime(m.year, m.month, 1);
    final last = DateTime(m.year, m.month + 1, 0);
    final out = <DateTime?>[];
    for (int i = 0; i < first.weekday % 7; i++) out.add(null);
    for (int d = 1; d <= last.day; d++) out.add(DateTime(m.year, m.month, d));
    while (out.length % 7 != 0) out.add(null);
    return out;
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _showCounterSwitcher(CounterProvider cp) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ...cp.counters.map(
                  (c) => Card(
                child: ListTile(
                  title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _dotPalette[cp.counters.indexOf(c) % _dotPalette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Radio<String>(
                        value: c.id,
                        groupValue: cp.activeCounterId,
                        onChanged: (v) async {
                          if (v == null) return;
                          await cp.switchCounter(v);
                          if (mounted) {
                            setState(() {});
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Rename',
                        onPressed: () async {
                          final name = await _askText("Rename counter", initial: c.name);
                          if (name != null && name.trim().isNotEmpty) {
                            await cp.renameCounter(c.id, name.trim());
                            if (mounted) setState(() {});
                          }
                        },
                        icon: Icon(PhosphorIcons.pencilSimple()),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          await cp.removeCounter(c.id);
                          if (mounted) setState(() {});
                        },
                        icon: Icon(PhosphorIcons.trash()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final name = await _askText("Add counter", hint: "Counter name");
                if (name != null && name.trim().isNotEmpty) {
                  await cp.addCounter(name.trim());
                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                }
              },
              icon: Icon(PhosphorIcons.plus()),
              label: const Text("Add Counter"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTopMenu(CounterProvider cp) async {
    final rb = _menuAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final off = rb.localToGlobal(Offset.zero);
    final sz = rb.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(off.dx, off.dy + sz.height + 6, off.dx + sz.width, 0),
      items: [
        PopupMenuItem(value: 'settings', child: Row(children: [Icon(PhosphorIcons.gear(), size: 18), const SizedBox(width: 8), const Text("General Settings")])),
        PopupMenuItem(value: 'add', child: Row(children: [Icon(PhosphorIcons.plus(), size: 18), const SizedBox(width: 8), const Text("Add Counter")])),
        PopupMenuItem(value: 'backup', child: Row(children: [Icon(PhosphorIcons.floppyDisk(), size: 18), const SizedBox(width: 8), const Text("Backup")])),
        PopupMenuItem(value: 'restore', child: Row(children: [Icon(PhosphorIcons.uploadSimple(), size: 18), const SizedBox(width: 8), const Text("Restore")])),
        PopupMenuItem(value: 'rate', child: Row(children: [Icon(PhosphorIcons.star(), size: 18), const SizedBox(width: 8), const Text("Rate Us")])),
        PopupMenuItem(value: 'about', child: Row(children: [Icon(PhosphorIcons.info(), size: 18), const SizedBox(width: 8), const Text("About Us")])),
      ],
    );

    if (!mounted || selected == null) return;

    if (selected == 'settings') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      if (mounted) setState(() {});
    } else if (selected == 'add') {
      final name = await _askText("Add counter", hint: "Counter name");
      if (name != null && name.trim().isNotEmpty) {
        await cp.addCounter(name.trim());
        if (mounted) setState(() {});
      }
    } else if (selected == 'backup') {
      final sp = context.read<SettingsProvider>();
      final path = await BackupService().exportBackup(counters: cp, settings: sp);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Backup saved: $path")));
    } else if (selected == 'restore') {
      final data = await BackupService().pickAndReadBackup();
      if (data == null) return;

      final storeMap = data['store'] as Map<String, dynamic>?;
      final settingsMap = data['settings'] as Map<String, dynamic>?;
      if (storeMap == null || settingsMap == null) return;

      final sp = context.read<SettingsProvider>();
      await cp.importFromMap(storeMap);
      await sp.importFromMap(settingsMap);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup restored successfully")));
      }
    } else if (selected == 'rate') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for rating us ⭐")));
    } else if (selected == 'about') {
      showAboutDialog(context: context, applicationName: "Mantra Jaap Tracker", applicationVersion: "1.0.0");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CounterProvider>();
    final settings = context.watch<SettingsProvider>();
    final cells = _monthCells(_currentMonth);
    final now = DateTime.now();

    final Color accent = settings.counterAccentColor;
    final border = Color.lerp(
      Theme.of(context).colorScheme.outlineVariant,
      accent,
      Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.18,
    )!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 98,
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 28),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Productive Mantra\nTracker",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "CormorantGaramond",
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                  height: .9,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: _menuAnchorKey,
            onPressed: () => _showTopMenu(cp),
            icon: Icon(PhosphorIcons.dotsThreeOutline(), size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 44, 14, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "One full cycle = ${settings.cycleSize}",
                              style: TextStyle(fontSize: 15, color: Theme.of(context).hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCounterSwitcher(cp),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                              label: Text(cp.activeCounter?.name ?? "Counter", maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                            }),
                            child: const Text("← Prev"),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                DateFormat('MMMM yyyy').format(_currentMonth),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: "CormorantGaramond", fontSize: 30, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                            }),
                            child: const Text("Next →"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _Week("SUN"),
                          _Week("MON"),
                          _Week("TUE"),
                          _Week("WED"),
                          _Week("THU"),
                          _Week("FRI"),
                          _Week("SAT"),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final d = cells[i];
                      if (d == null) return const SizedBox();

                      final day = d;
                      final iso = _iso(day);
                      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

                      final cyclesPerCounter = <MapEntry<int, int>>[];
                      for (int ci = 0; ci < cp.counters.length; ci++) {
                        final c = cp.counters[ci];
                        final full = ((c.countsByDate[iso] ?? 0) ~/ settings.cycleSize);
                        if (full > 0) cyclesPerCounter.add(MapEntry(ci, full));
                      }

                      final visibleRows = cyclesPerCounter.take(4).toList();
                      final hiddenTypeCount = cyclesPerCounter.length - visibleRows.length;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CounterScreen(date: day)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isToday ? accent : border,
                              width: isToday ? 1.6 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${day.day}",
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isToday ? accent : null,
                                ),
                              ),
                              const SizedBox(height: 4),

                              ...visibleRows.map((e) {
                                final color = _dotPalette[e.key % _dotPalette.length];
                                final fullCycles = e.value;
                                final shownDots = fullCycles > 2 ? 2 : fullCycles;
                                final extra = fullCycles - shownDots;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      for (int j = 0; j < shownDots; j++)
                                        Container(
                                          margin: const EdgeInsets.only(right: 2),
                                          width: 6.2,
                                          height: 6.2,
                                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                        ),
                                      if (extra > 0)
                                        Flexible(
                                          child: Text(
                                            "+$extra",
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontFamily: "Inter",
                                              fontSize: 8.8,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),

                              if (hiddenTypeCount > 0)
                                Text(
                                  "+$hiddenTypeCount more",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: cells.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Week extends StatelessWidget {
  final String t;
  const _Week(this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: const TextStyle(
        fontFamily: "Inter",
        fontSize: 12,
        letterSpacing: 2.1,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}