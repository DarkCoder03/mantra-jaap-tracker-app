import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'root_shell.dart';

/// Opening animation (logo blooms, then the app scales in beneath it) and the
/// switch between onboarding and the main app.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _launch.value = 1;
      } else {
        _launch.forward();
      }
    });
  }

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final onboardingDone = context.select<SettingsProvider, bool>((s) => s.onboardingDone);
    final background = Theme.of(context).colorScheme.surface;

    final content = AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.slow),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: onboardingDone
          ? const RootShell(key: ValueKey('shell'))
          : OnboardingScreen(
              key: const ValueKey('onboarding'),
              onDone: () {
                final settings = context.read<SettingsProvider>();
                settings.update(() => settings.onboardingDone = true);
              },
            ),
    );

    return AnimatedBuilder(
      animation: _launch,
      child: content,
      builder: (context, child) {
        final t = _launch.value;
        final appIn = AppMotion.enter.transform(_interval(t, 0.40, 1.0));
        final logoIn = AppMotion.enter.transform(_interval(t, 0.0, 0.45));
        final logoOut = AppMotion.exit.transform(_interval(t, 0.45, 0.85));

        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: appIn,
              child: Transform.scale(scale: 0.94 + 0.06 * appIn, child: child),
            ),
            if (t < 1)
              IgnorePointer(
                child: ColoredBox(
                  color: background.withValues(alpha: 1 - logoOut),
                  child: Center(
                    child: Opacity(
                      opacity: logoIn * (1 - logoOut),
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * logoIn + 0.15 * logoOut,
                        child: ClipRRect(
                          borderRadius: AppRadius.lgAll,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(width: 96, height: 96),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
