import 'package:flutter/material.dart';

class AppColors {
  // Primary palette: Sage Green + Butter Yellow + Ivory
  static const sage = Color(0xFF91A88B);
  static const sageLight = Color(0xFFE5ECE1);
  static const butterYellow = Color(0xFFF1D98A);
  static const ivory = Color(0xFFFAF8EF);

  // Supporting colors
  static const ink = Color(0xFF344438);
  static const muted = Color(0xFF747D72);
  static const border = Color(0xFFE5E5D9);
  static const card = Color(0xFFFFFFFF);
  static const inputBackground = Color(0xFFF4F3E9);

  // Status colors
  static const green = Color(0xFF527653);
  static const orange = Color(0xFFAC7136);
  static const red = Color(0xFFC45F57);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.ivory,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.sage,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.sage,
          onPrimary: AppColors.ink,
          secondary: AppColors.butterYellow,
          onSecondary: AppColors.ink,
          surface: AppColors.card,
          onSurface: AppColors.ink,
          error: AppColors.red,
          onError: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.ivory,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          titleLarge: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.ink,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),

        cardTheme: CardTheme(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.sage,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sage,
            foregroundColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.card,
          indicatorColor: AppColors.sageLight,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
            ),
          ),
        ),
      );
}