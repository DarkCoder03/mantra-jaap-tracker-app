import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Spacing scale. Every screen uses these values; nothing is hard-coded.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal margin shared by every page.
  static const double page = 16;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: page);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

/// Corner radii. Hierarchy: small tiles < inputs < cards < dialogs/sheets.
abstract final class AppRadius {
  static const double sm = 12; // calendar cells, icon tiles, snackbars
  static const double md = 16; // text fields, menus
  static const double lg = 20; // cards
  static const double xl = 28; // dialogs and bottom sheets (M3 spec)

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Motion tokens (M3 durations and easing).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  /// M3 "emphasized decelerate": things entering or growing.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// M3 "emphasized accelerate": things leaving or shrinking.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// M3 "standard": everything else.
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// [d], or zero when the person has turned on "reduce motion".
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

abstract final class AppFonts {
  static const String serif = 'CormorantGaramond';
  static const String sans = 'Inter';
}

abstract final class AppTheme {
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    },
  );

  /// Builds the one theme every screen draws from.
  ///
  /// [amoled] only applies to dark brightness: pure #000000 surfaces with a
  /// vibrant scheme so accents stay punchy against true black.
  static ThemeData build({
    required Brightness brightness,
    required Color seed,
    bool amoled = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final isAmoled = isDark && amoled;

    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: isAmoled ? DynamicSchemeVariant.vibrant : DynamicSchemeVariant.tonalSpot,
    );

    // Neutral (untinted) surfaces keep the app's original calm look.
    final ColorScheme scheme;
    if (isAmoled) {
      scheme = base.copyWith(
        surface: const Color(0xFF000000),
        surfaceDim: const Color(0xFF000000),
        surfaceBright: const Color(0xFF1A1A1A),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF000000),
        surfaceContainer: const Color(0xFF000000),
        surfaceContainerHigh: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF1C1C1C),
        outlineVariant: const Color(0xFF262626),
      );
    } else if (isDark) {
      scheme = base.copyWith(
        surface: const Color(0xFF0A0A0B),
        surfaceDim: const Color(0xFF0A0A0B),
        surfaceBright: const Color(0xFF2A2A2E),
        surfaceContainerLowest: const Color(0xFF050506),
        surfaceContainerLow: const Color(0xFF121215),
        surfaceContainer: const Color(0xFF18181B),
        surfaceContainerHigh: const Color(0xFF1F1F23),
        surfaceContainerHighest: const Color(0xFF27272A),
        outlineVariant: const Color(0xFF2A2A2E),
      );
    } else {
      scheme = base.copyWith(
        surface: const Color(0xFFF7F7F8),
        surfaceDim: const Color(0xFFE4E4E7),
        surfaceBright: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFFFFFFF),
        surfaceContainer: const Color(0xFFF1F1F3),
        surfaceContainerHigh: const Color(0xFFEBEBEE),
        surfaceContainerHighest: const Color(0xFFE4E4E7),
        outlineVariant: const Color(0xFFE4E4E7),
      );
    }

    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      fontFamily: AppFonts.sans,
      textTheme: textTheme,
      pageTransitionsTheme: _pageTransitions,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 26, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isAmoled ? Colors.black : scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: AppSpacing.md,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  /// Type scale: Cormorant Garamond for display and headings, Inter for
  /// everything people read or tap.
  static TextTheme _textTheme(ColorScheme scheme) {
    const serif = AppFonts.serif;
    const sans = AppFonts.sans;
    return TextTheme(
      // The big number on the counter screen.
      displayLarge: const TextStyle(fontFamily: sans, fontSize: 88, fontWeight: FontWeight.w400, height: 1.0, letterSpacing: -2),
      // Mantra name on the counter screen, onboarding titles.
      displayMedium: const TextStyle(fontFamily: serif, fontSize: 44, fontWeight: FontWeight.w600, height: 1.05),
      displaySmall: const TextStyle(fontFamily: serif, fontSize: 36, fontWeight: FontWeight.w600, height: 1.1),
      // Page titles (expanded app bar).
      headlineLarge: const TextStyle(fontFamily: serif, fontSize: 34, fontWeight: FontWeight.w600, height: 1.1),
      headlineMedium: const TextStyle(fontFamily: serif, fontSize: 30, fontWeight: FontWeight.w600, height: 1.1),
      // Card titles, month name, dialog titles.
      headlineSmall: const TextStyle(fontFamily: serif, fontSize: 26, fontWeight: FontWeight.w600, height: 1.15),
      titleLarge: const TextStyle(fontFamily: sans, fontSize: 20, fontWeight: FontWeight.w600, height: 1.25),
      titleMedium: const TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
      titleSmall: const TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: const TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: const TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
      bodySmall: TextStyle(fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurfaceVariant),
      labelLarge: const TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
      labelMedium: const TextStyle(fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
      labelSmall: const TextStyle(fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3),
    );
  }
}
