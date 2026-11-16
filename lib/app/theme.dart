// Light and dark ThemeData for TaskMapFlow.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Theme Palette (Reference Visual Design)
  static const Color darkBackground = Color(0xFF0C0B10);
  static const Color darkSurface = Color(0xFF13121A);
  static const Color darkInputFill = Color(0xFF171520);
  static const Color darkInputBorder = Color(0xFF272435);
  static const Color darkInputBorderFocus = Color(0xFFB49BFF);
  static const Color darkTextPrimary = Color(0xFFF3F2F7);
  static const Color darkTextSecondary = Color(0xFF8E8B9E);
  static const Color darkTextHint = Color(0xFF585567);
  static const Color darkPrimaryPurple = Color(0xFFB49BFF);
  static const Color darkOnPrimary = Color(0xFF0D0C13);
  static const Color darkErrorContainer = Color(0xFF2E151A);
  static const Color darkOnErrorContainer = Color(0xFFFF8E99);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF7F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInputFill = Color(0xFFFFFFFF);
  static const Color lightInputBorder = Color(0xFFDCD8E8);
  static const Color lightInputBorderFocus = Color(0xFF7C5CE8);
  static const Color lightTextPrimary = Color(0xFF171522);
  static const Color lightTextSecondary = Color(0xFF5E5B6E);
  static const Color lightTextHint = Color(0xFF9A97A8);
  static const Color lightPrimaryPurple = Color(0xFF7C5CE8);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFEDEE);
  static const Color lightOnErrorContainer = Color(0xFFD32F2F);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightPrimaryPurple,
          onPrimary: AppColors.lightOnPrimary,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          errorContainer: AppColors.lightErrorContainer,
          onErrorContainer: AppColors.lightOnErrorContainer,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightInputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightInputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.lightInputBorderFocus,
              width: 1.5,
            ),
          ),
          hintStyle: const TextStyle(
            color: AppColors.lightTextHint,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkPrimaryPurple,
          onPrimary: AppColors.darkOnPrimary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          errorContainer: AppColors.darkErrorContainer,
          onErrorContainer: AppColors.darkOnErrorContainer,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkInputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkInputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.darkInputBorderFocus,
              width: 1.5,
            ),
          ),
          hintStyle: const TextStyle(
            color: AppColors.darkTextHint,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
