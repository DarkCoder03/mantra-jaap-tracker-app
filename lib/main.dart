import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/counter_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

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
      child: Consumer<SettingsProvider>(
        builder: (_, settings, __) {
          final mode = settings.themeMode == AppThemeMode.system
              ? ThemeMode.system
              : (settings.themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light);

          PageTransitionsTheme transitions = const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            },
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mantra Jaap Tracker',
            themeMode: mode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: settings.primaryColor,
              scaffoldBackgroundColor: const Color(0xFFF7F7F8),
              fontFamily: 'Inter',
              pageTransitionsTheme: transitions,
              splashFactory: InkSparkle.splashFactory,
              textTheme: const TextTheme(
                displayLarge: TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600),
                headlineLarge: TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600),
                titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: settings.primaryColor,
              scaffoldBackgroundColor: const Color(0xFF0A0A0B),
              fontFamily: 'Inter',
              pageTransitionsTheme: transitions,
              splashFactory: InkSparkle.splashFactory,
              textTheme: const TextTheme(
                displayLarge: TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600),
                headlineLarge: TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600),
                titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}