// lib/core/theme/app_theme.dart
// Requires: google_fonts (add with `flutter pub add google_fonts`)
// Flutter 3.27+ (uses CardThemeData, WidgetStateProperty)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------- Colors ----------
class AppColors {
  AppColors._();

  static const primary = Color(0xFF3A86FF); // ocean blue
  static const sunshine = Color(0xFFFFC93C); // XP, coins, highlights
  static const purple = Color(0xFF8E7CFF);
  static const coral = Color(0xFFFF6B6B);
  static const orange = Color(0xFFFF9F1C);
  static const green = Color(0xFF3CCB7F); // success

  static const background = Color(0xFFFFF8EC); // cream
  static const surface = Colors.white;
  static const text = Color(0xFF1F2A44); // navy
  static const textSoft = Color(0xFF5B6784);

  // Feedback: never red for mistakes
  static const success = green;
  static const tryAgain = orange;
  static const xp = sunshine;
}

/// ---------- Track colors ----------
enum Track { math, science, language, geography, eco }

extension TrackStyle on Track {
  String get label => switch (this) {
        Track.math => 'Math Adventures',
        Track.science => 'Science Explorer',
        Track.language => 'Language & Reading',
        Track.geography => 'World Explorer',
        Track.eco => 'Eco & Nature',
      };

  Color get color => switch (this) {
        Track.math => AppColors.primary,
        Track.science => AppColors.purple,
        Track.language => AppColors.coral,
        Track.geography => AppColors.orange,
        Track.eco => AppColors.green,
      };
}

/// ---------- Sizing ----------
class AppSizes {
  AppSizes._();

  static const tapTarget = 56.0; // minimum for kids (Material minimum is 48)
  static const radius = 20.0;
  static const radiusLarge = 28.0;
  static const pad = 16.0;
  static const padLarge = 24.0;
}

/// ---------- Theme ----------
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme() {
    final body = GoogleFonts.nunitoTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    TextStyle heading(double size) => GoogleFonts.fredoka(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        );

    return body.copyWith(
      displayLarge: heading(40),
      displayMedium: heading(34),
      headlineLarge: heading(30),
      headlineMedium: heading(26),
      headlineSmall: heading(22),
      titleLarge: heading(22),
      titleMedium: heading(20),
      titleSmall: heading(18),
      // Body never below 16sp; main text 18-20sp
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 20, height: 1.4),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 18, height: 1.4),
      bodySmall: body.bodySmall?.copyWith(fontSize: 16, height: 1.4),
      labelLarge: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.sunshine,
      onSecondary: AppColors.text,
      tertiary: AppColors.purple,
      onTertiary: Colors.white,
      error: AppColors.tryAgain, // soft orange, not red
      onError: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    final text = _textTheme();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(size: 28),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(96, AppSizes.tapTarget + 4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: text.labelLarge,
          shape: shape,
          elevation: 3,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(96, AppSizes.tapTarget),
          side: const BorderSide(color: AppColors.primary, width: 2.5),
          textStyle: text.labelLarge,
          shape: shape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppSizes.tapTarget),
          textStyle: text.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.tapTarget),
          iconSize: 30,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.textSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          borderSide: const BorderSide(color: Color(0xFFE3DCCB), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          borderSide: const BorderSide(color: Color(0xFFE3DCCB), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          borderSide: const BorderSide(color: AppColors.tryAgain, width: 3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          borderSide: const BorderSide(color: AppColors.tryAgain, width: 3),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.sunshine,
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 30)),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.sunshine,
        linearTrackColor: const Color(0xFFF1E7CF),
        linearMinHeight: 14,
        borderRadius: BorderRadius.circular(10),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: Colors.white),
        shape: shape,
      ),

      chipTheme: ChipThemeData(
        labelStyle: text.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: StadiumBorder(),
      ),
    );
  }
}

// Usage in main.dart:
//   MaterialApp.router(theme: AppTheme.light, ...)
// Track color:  Track.math.color
// XP bar:       LinearProgressIndicator(value: 0.6)  // uses sunshine track
