import 'package:flutter/material.dart';
import '../models/mantra_icon.dart';
import '../providers/counter_provider.dart';
import '../theme/app_theme.dart';
import 'app_ui.dart';
import 'counter_avatar.dart';

class CounterDraft {
  final String name;
  final String iconId;
  final Color color;
  final int dailyGoalCycles;

  /// Empty string means "no custom symbol".
  final String customGlyph;

  const CounterDraft({
    required this.name,
    required this.iconId,
    required this.color,
    required this.dailyGoalCycles,
    required this.customGlyph,
  });
}

/// Create a counter (no [initial]) or edit one. Returns null if cancelled.
Future<CounterDraft?> showCounterEditor(
  BuildContext context, {
  required int cycleSize,
  CounterProfile? initial,
  Color? suggestedColor,
  String? title,
}) {
  return showModalBottomSheet<CounterDraft>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _CounterEditor(
        title: title ?? (initial == null ? 'New counter' : 'Edit counter'),
        initial: initial,
        cycleSize: cycleSize,
        suggestedColor: suggestedColor ?? CounterProvider.palette.first,
      ),
    ),
  );
}

class _CounterEditor extends StatefulWidget {
  final String title;
  final CounterProfile? initial;
  final int cycleSize;
  final Color suggestedColor;

  const _CounterEditor({
    required this.title,
    required this.initial,
    required this.cycleSize,
    required this.suggestedColor,
  });

  @override
  State<_CounterEditor> createState() => _CounterEditorState();
}

class _CounterEditorState extends State<_CounterEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _custom = TextEditingController(text: widget.initial?.customGlyph ?? '');
  late String _iconId = widget.initial?.iconId ?? MantraIcons.fallbackId;
  late Color _color = widget.initial?.color ?? widget.suggestedColor;
  late int _goal = widget.initial?.dailyGoalCycles ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _custom.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;
  bool get _isCustom => _iconId == MantraIcons.customId;

  void _save() {
    if (!_valid) return;
    Navigator.pop(
      context,
      CounterDraft(
        name: _name.text.trim(),
        iconId: _iconId,
        color: _color,
        dailyGoalCycles: _goal,
        customGlyph: _isCustom ? _custom.text.trim() : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = MantraIcons.byId(_iconId);
    final customText = _custom.text.trim();

    return SheetScaffold(
      title: widget.title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: CounterAvatar(
                    key: ValueKey('$_iconId-${_color.toARGB32()}-$customText'),
                    icon: icon,
                    color: _color,
                    size: 56,
                    customGlyph: customText,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: widget.initial == null,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Mantra name',
                      hintText: 'Om Namah Shivaya',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _FieldLabel('Symbol'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.82,
              children: [
                for (final i in MantraIcons.all)
                  _SymbolChoice(
                    icon: i,
                    color: _color,
                    customGlyph: customText,
                    selected: i.id == _iconId,
                    onTap: () => setState(() => _iconId = i.id),
                  ),
              ],
            ),
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _isCustom
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: TextField(
                        controller: _custom,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'Your symbol',
                          hintText: 'ॐ, 🙏 or a short word',
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _FieldLabel('Colour'),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final c in CounterProvider.palette)
                  _ColorChoice(
                    color: c,
                    selected: c.toARGB32() == _color.toARGB32(),
                    onTap: () => setState(() => _color = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _FieldLabel('Daily goal'),
            GoalPicker(
              value: _goal,
              cycleSize: widget.cycleSize,
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _valid ? _save : null,
                    child: Text(widget.initial == null ? 'Create counter' : 'Save changes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// A symbol in the picker. Selection is shown by a single ring, no boxes.
class _SymbolChoice extends StatelessWidget {
  final MantraIcon icon;
  final Color color;
  final String customGlyph;
  final bool selected;
  final VoidCallback onTap;

  const _SymbolChoice({
    required this.icon,
    required this.color,
    required this.customGlyph,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: icon.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? color : Colors.transparent, width: 2),
              ),
              child: ExcludeSemantics(
                child: CounterAvatar(icon: icon, color: color, size: 48, customGlyph: customGlyph),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              icon.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}

/// Daily goal as five rounded pills: 1, 2, 4, 8 and 16 malas.
class GoalPicker extends StatelessWidget {
  final int value;
  final int cycleSize;
  final ValueChanged<int> onChanged;

  static const presets = [1, 2, 4, 8, 16];

  const GoalPicker({super.key, required this.value, required this.cycleSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPreset = presets.contains(value);
    final caption = isPreset
        ? '$value ${value == 1 ? 'mala' : 'malas'} a day, ${value * cycleSize} chants'
        : 'Current goal: $value malas a day. Pick one above to change it.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (i, p) in presets.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GoalPill(
                  value: p,
                  selected: value == p,
                  onTap: () => onChanged(p),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(caption, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _GoalPill extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _GoalPill({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$value ${value == 1 ? 'mala' : 'malas'}',
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
                child: ExcludeSemantics(child: Text('$value')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adjust just the daily goal. Returns null if dismissed.
Future<int?> showDailyGoalSheet(BuildContext context, {required int initial, required int cycleSize}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _GoalSheet(initial: initial, cycleSize: cycleSize),
  );
}

class _GoalSheet extends StatefulWidget {
  final int initial;
  final int cycleSize;
  const _GoalSheet({required this.initial, required this.cycleSize});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Daily goal',
      subtitle: 'How many malas do you want to complete each day?',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoalPicker(value: _value, cycleSize: widget.cycleSize, onChanged: (v) => setState(() => _value = v)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: () => Navigator.pop(context, _value), child: const Text('Save goal')),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}