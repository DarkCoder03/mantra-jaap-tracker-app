import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/counter_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/app_entry.dart';
import 'theme/app_theme.dart';
import 'utils/app_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  final counterProvider = CounterProvider();
  await counterProvider.load();

  runApp(MyApp(
    settingsProvider: settingsProvider,
    counterProvider: counterProvider,
  ));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final CounterProvider counterProvider;

  const MyApp({
    super.key,
    required this.settingsProvider,
    required this.counterProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<CounterProvider>.value(value: counterProvider),
      ],
      // Rebuild the app (and its themes) only when theme-related settings change.
      child: Selector<SettingsProvider, (AppThemeMode, String)>(
        selector: (_, s) => (s.themeMode, s.primaryThemeKey),
        builder: (context, _, _) {
          final settings = context.read<SettingsProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: kAppName,
            themeMode: settings.materialThemeMode,
            theme: AppTheme.build(brightness: Brightness.light, seed: settings.primaryColor),
            darkTheme: AppTheme.build(
              brightness: Brightness.dark,
              seed: settings.primaryColor,
              amoled: settings.isAmoled,
            ),
            themeAnimationDuration: AppMotion.medium,
            themeAnimationCurve: AppMotion.standard,
            home: const AppEntry(),
          );
        },
      ),
    );
  }
}
