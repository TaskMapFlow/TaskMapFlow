// Light and dark ThemeData for TaskMapFlow.
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primarySeed = Color(0xFF4A6CF7);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primarySeed,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primarySeed,
          brightness: Brightness.dark,
        ),
      );
}
