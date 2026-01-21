// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF15306C);
  static const Color primaryDark = Color(0xFF15306C);

  static const Color secondary = Color(0xFFEB9A4A);
  static const Color secondaryDark = Color(0xFFE07429);

  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkBg = Color(0xFF121212);

  static const Color lightText = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFECECEC);

  static const Color lightSubText = Color(0xFF6D6D6D);
  static const Color darkSubText = Color(0xFF9E9E9E);

  static const Color lightIcon = Color(0xFF333333);
  static const Color darkIcon = Color(0xFFE0E0E0);

  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.light,
    ),
    // primarySwatch: Colors.red,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      iconTheme: IconThemeData(color: lightIcon),
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: primary,
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    primaryColor: primary,
    iconTheme: const IconThemeData(color: lightIcon),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: lightText),
      titleLarge: TextStyle(color: lightText),
      bodyLarge: TextStyle(color: lightText),
      bodySmall: TextStyle(color: lightSubText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CustomFadeForwardsPageTransitions(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

class CustomFadeForwardsPageTransitions
    extends FadeForwardsPageTransitionsBuilder {
  @override
  final Duration transitionDuration;

  CustomFadeForwardsPageTransitions({
    this.transitionDuration = const Duration(milliseconds: 600),
    Color? backgroundColor,
  }) : super(backgroundColor: backgroundColor);
}
