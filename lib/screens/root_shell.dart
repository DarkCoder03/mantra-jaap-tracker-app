import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// Bottom navigation for the three main tabs.
///
/// All tabs stay mounted (like an IndexedStack) so scroll position and the
/// calendar's month survive tab switches; the visible one fades and scales in.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _tabs = <Widget>[HomeScreen(), StatisticsScreen(), SettingsScreen()];

  int _index = 0;
  bool _exiting = false;

  Future<void> _handleBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    if (_exiting) return;
    setState(() => _exiting = true);
    await Future<void>.delayed(AppMotion.of(context, AppMotion.medium));
    await SystemNavigator.pop();
    // If the platform kept us alive (e.g. multi-window), come back visibly.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _exiting = false);
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AnimatedOpacity(
        opacity: _exiting ? 0 : 1,
        duration: duration,
        curve: AppMotion.exit,
        child: AnimatedScale(
          scale: _exiting ? 0.92 : 1,
          duration: duration,
          curve: AppMotion.exit,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                for (final (i, tab) in _tabs.indexed) _TabLayer(active: i == _index, child: tab),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded),
                  selectedIcon: Icon(Icons.insert_chart_rounded),
                  label: 'Statistics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabLayer extends StatelessWidget {
  final bool active;
  final Widget child;

  const _TabLayer({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    final curve = active ? AppMotion.enter : AppMotion.exit;

    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: curve,
          child: AnimatedScale(
            scale: active ? 1 : 0.97,
            duration: duration,
            curve: curve,
            // Hidden tabs stop animating, don't take focus, and don't
            // contribute Hero tags to page transitions.
            child: TickerMode(
              enabled: active,
              child: HeroMode(
                enabled: active,
                child: ExcludeFocus(excluding: !active, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
