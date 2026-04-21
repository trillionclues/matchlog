// MatchLog theme definition.

library;

import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MatchLogColors.background,
        colorScheme: const ColorScheme.dark(
          primary: MatchLogColors.primary,
          onPrimary: Colors.white,
          secondary: MatchLogColors.secondary,
          onSecondary: Colors.white,
          surface: MatchLogColors.surface,
          onSurface: MatchLogColors.textPrimary,
          error: MatchLogColors.error,
          onError: Colors.white,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: MatchLogColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: MatchLogTypography.headlineMedium,
          iconTheme: const IconThemeData(color: MatchLogColors.textPrimary),
          actionsIconTheme:
              const IconThemeData(color: MatchLogColors.textPrimary),
        ),

        cardTheme: CardTheme(
          color: MatchLogColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            side: const BorderSide(
              color: MatchLogColors.surfaceBorder,
              width: 1,
            ),
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: MatchLogColors.surface,
          selectedItemColor: MatchLogColors.primary,
          unselectedItemColor: MatchLogColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MatchLogColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: MatchLogColors.surfaceBorder,
            disabledForegroundColor: MatchLogColors.textDisabled,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge,
            elevation: 0,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MatchLogColors.primary,
            textStyle: MatchLogTypography.labelLarge,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MatchLogColors.primary,
            side: const BorderSide(color: MatchLogColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MatchLogColors.surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide: const BorderSide(color: MatchLogColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogColors.error, width: 2),
          ),
          hintStyle: MatchLogTypography.bodyMedium
              .copyWith(color: MatchLogColors.textTertiary),
          labelStyle: MatchLogTypography.labelSmall,
          errorStyle:
              MatchLogTypography.bodySmall.copyWith(color: MatchLogColors.error),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: MatchLogColors.surfaceElevated,
          selectedColor: MatchLogColors.primarySurface,
          disabledColor: MatchLogColors.surfaceBorder,
          labelStyle: MatchLogTypography.labelSmall,
          side: const BorderSide(color: MatchLogColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedFull,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        dividerTheme: const DividerThemeData(
          color: MatchLogColors.surfaceBorder,
          thickness: 1,
          space: 0,
        ),

        dialogTheme: DialogTheme(
          backgroundColor: MatchLogColors.surfaceElevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedLg,
          ),
          titleTextStyle: MatchLogTypography.headlineSmall,
          contentTextStyle: MatchLogTypography.bodyMedium,
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: MatchLogColors.surfaceElevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MatchLogSpacing.radiusLg),
            ),
          ),
        ),

        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: MatchLogColors.textSecondary,
          titleTextStyle: MatchLogTypography.bodyMedium
              .copyWith(color: MatchLogColors.textPrimary),
          subtitleTextStyle: MatchLogTypography.bodySmall,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),

        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogColors.primary;
            }
            return MatchLogColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogColors.primarySurface;
            }
            return MatchLogColors.surfaceBorder;
          }),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: MatchLogColors.primary,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: MatchLogColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: CircleBorder(),
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: MatchLogColors.surfaceElevated,
          contentTextStyle: MatchLogTypography.bodyMedium
              .copyWith(color: MatchLogColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
          ),
          behavior: SnackBarBehavior.floating,
        ),

        tabBarTheme: TabBarTheme(
          labelColor: MatchLogColors.primary,
          unselectedLabelColor: MatchLogColors.textTertiary,
          indicatorColor: MatchLogColors.primary,
          labelStyle: MatchLogTypography.labelLarge,
          unselectedLabelStyle: MatchLogTypography.labelLarge
              .copyWith(color: MatchLogColors.textTertiary),
        ),

        textTheme: TextTheme(
          displayLarge: MatchLogTypography.headlineXL,
          displayMedium: MatchLogTypography.headlineLarge,
          displaySmall: MatchLogTypography.headlineMedium,
          headlineMedium: MatchLogTypography.headlineMedium,
          headlineSmall: MatchLogTypography.headlineSmall,
          titleLarge: MatchLogTypography.headlineSmall,
          titleMedium: MatchLogTypography.labelLarge,
          titleSmall: MatchLogTypography.labelSmall,
          bodyLarge: MatchLogTypography.bodyLarge,
          bodyMedium: MatchLogTypography.bodyMedium,
          bodySmall: MatchLogTypography.bodySmall,
          labelLarge: MatchLogTypography.labelLarge,
          labelSmall: MatchLogTypography.labelSmall,
        ),
      );
}
