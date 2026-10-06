import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// The collapsing header every tab uses, so titles line up across the app.
class AppPageHeader extends StatelessWidget {
  final String title;
  final Widget? leadingMark;
  final List<Widget> actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.leadingMark,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.medium(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingMark != null) ...[leadingMark!, const SizedBox(width: AppSpacing.md)],
          Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [...actions, const SizedBox(width: AppSpacing.xs)],
    );
  }
}

/// Small coloured heading above a group of content.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A card whose rows are separated by inset dividers (settings-style).
class CardGroup extends StatelessWidget {
  final List<Widget> children;

  const CardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            child,
          ],
        ],
      ),
    );
  }
}

/// Rounded label used for streaks and small status chips.
class InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  final Widget? leading;

  const InfoPill({super.key, required this.label, required this.color, this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  const ColorDot(this.color, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Title + body layout shared by every bottom sheet.
class SheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SheetScaffold({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          Flexible(child: child),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// Pick one value from a list. Returns null if dismissed.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<SettingOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SheetScaffold(
        title: title,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          children: [
            for (final o in options)
              ListTile(
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                leading: o.color != null ? ColorDot(o.color!) : null,
                title: Text(o.label),
                selected: o.value == selected,
                trailing: o.value == selected
                    ? Icon(Icons.check_rounded, color: scheme.primary, size: 20)
                    : null,
                onTap: () => Navigator.pop(ctx, o.value),
              ),
          ],
        ),
      );
    },
  );
}

/// Single text field dialog. Returns the trimmed text, or null if cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String hint = '',
  String initial = '',
  String confirmLabel = 'Save',
  bool numeric = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      hint: hint,
      initial: initial,
      confirmLabel: confirmLabel,
      numeric: numeric,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;
  final String confirmLabel;
  final bool numeric;

  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initial,
    required this.confirmLabel,
    required this.numeric,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        textCapitalization: widget.numeric ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Yes/no confirmation. [destructive] paints the confirm button in the error colour.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}