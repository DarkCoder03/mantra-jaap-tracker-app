import 'package:flutter/material.dart';
import '../models/mantra_icon.dart';
import '../providers/counter_provider.dart';
import '../services/volume_key_service.dart';
import '../theme/app_theme.dart';
import '../widgets/counter_avatar.dart';
import '../widgets/progress_ring.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _IntroPage {
  final String title;
  final String body;
  final WidgetBuilder illustration;
  const _IntroPage({required this.title, required this.body, required this.illustration});
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  late final List<_IntroPage> _pages = [
    VolumeKeyService.isSupported
        ? _IntroPage(
            title: 'Count with volume buttons',
            body: 'Keep your eyes closed and your phone in hand. Volume up adds a bead, volume down takes one back.',
            illustration: (_) => const _VolumeIllustration(),
          )
        : _IntroPage(
            title: 'Count without looking',
            body: 'Hide the minus button and tap anywhere on the ring to count, so your eyes can stay closed.',
            illustration: (_) => const _VolumeIllustration(showButtons: false),
          ),
    _IntroPage(
      title: 'Keep your streak alive',
      body: 'Finish at least one mala a day to build a streak. Set a daily goal and watch the ring fill as you chant.',
      illustration: (_) => const _StreakIllustration(),
    ),
    _IntroPage(
      title: 'A counter for every mantra',
      body: 'Give each mantra its own name, symbol and colour, and switch between them from the home screen.',
      illustration: (_) => const _CountersIllustration(),
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _controller.nextPage(duration: AppMotion.of(context, AppMotion.medium), curve: AppMotion.standard);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: TextButton(onPressed: _isLast ? null : widget.onDone, child: const Text('Skip')),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    var delta = 0.0;
                    if (_controller.hasClients && _controller.position.haveDimensions) {
                      delta = (_controller.page ?? _page.toDouble()) - i;
                    }
                    final visible = (1 - delta.abs()).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: visible,
                      child: Transform.scale(scale: 0.9 + 0.1 * visible, child: child),
                    );
                  },
                  child: _IntroPageView(page: _pages[i]),
                ),
              ),
            ),
            _PageDots(count: _pages.length, index: _page),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: Text(_isLast ? 'Get started' : 'Next', key: ValueKey(_isLast)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 240, child: Center(child: page.illustration(context))),
              const SizedBox(height: AppSpacing.xxl),
              Text(page.title, textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  const _PageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == index ? scheme.primary : scheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Illustrations (built from app widgets, no image assets needed) ---------

class _VolumeIllustration extends StatelessWidget {
  final bool showButtons;
  const _VolumeIllustration({this.showButtons = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          progress: 62 / 108,
          size: 190,
          strokeWidth: 12,
          color: scheme.primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('62', style: theme.textTheme.displayLarge?.copyWith(fontSize: 64)),
              Text('of 108', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (showButtons) ...[
          const SizedBox(width: AppSpacing.xl),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SideKey(icon: Icons.add_rounded, highlighted: true),
              const SizedBox(height: AppSpacing.sm),
              _SideKey(icon: Icons.remove_rounded),
            ],
          ),
        ],
      ],
    );
  }
}

class _SideKey extends StatelessWidget {
  final IconData icon;
  final bool highlighted;
  const _SideKey({required this.icon, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        color: highlighted ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      child: Icon(icon, size: 20, color: highlighted ? scheme.onPrimary : scheme.onSurfaceVariant),
    );
  }
}

class _StreakIllustration extends StatelessWidget {
  const _StreakIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          progress: 0.8,
          size: 150,
          strokeWidth: 12,
          color: scheme.primary,
          child: const Text('🔥', style: TextStyle(fontSize: 56, height: 1)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 7; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < 6 ? scheme.primary : Colors.transparent,
                        border: Border.all(color: scheme.primary, width: 1.5),
                      ),
                      child: i < 6 ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary) : null,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(labels[i], style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CountersIllustration extends StatelessWidget {
  const _CountersIllustration();

  @override
  Widget build(BuildContext context) {
    const ids = ['shri', 'raam', 'shiv', 'krishna', 'hanuman', 'durga'];
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, id) in ids.indexed)
          CounterAvatar(
            icon: MantraIcons.byId(id),
            color: CounterProvider.palette[i % CounterProvider.palette.length],
            size: 72,
          ),
      ],
    );
  }
}