library;

import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: MatchLogLightColors.background,
        colorScheme: const ColorScheme.light(
          primary: MatchLogLightColors.primary,
          onPrimary: Colors.white,
          secondary: MatchLogLightColors.secondary,
          onSecondary: Colors.white,
          surface: MatchLogLightColors.surface,
          onSurface: MatchLogLightColors.textPrimary,
          error: MatchLogLightColors.error,
          onError: Colors.white,
          outline: MatchLogLightColors.surfaceBorder,
          outlineVariant: MatchLogLightColors.surfaceBorder,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MatchLogLightColors.background,
          foregroundColor: MatchLogLightColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          iconTheme:
              const IconThemeData(color: MatchLogLightColors.textPrimary),
          actionsIconTheme:
              const IconThemeData(color: MatchLogLightColors.textPrimary),
        ),
        cardTheme: CardTheme(
          color: MatchLogLightColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            side: const BorderSide(
              color: MatchLogLightColors.surfaceBorder,
              width: 1,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: MatchLogLightColors.surface,
          selectedItemColor: MatchLogLightColors.primary,
          unselectedItemColor: MatchLogLightColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MatchLogLightColors.textPrimary,
            foregroundColor: MatchLogLightColors.surface,
            disabledBackgroundColor: MatchLogLightColors.surfaceBorder,
            disabledForegroundColor: MatchLogLightColors.textDisabled,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogLightColors.surface,
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MatchLogLightColors.primary,
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogLightColors.primary,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MatchLogLightColors.textPrimary,
            side: const BorderSide(color: MatchLogLightColors.surfaceBorder),
            backgroundColor: MatchLogLightColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogLightColors.textPrimary,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MatchLogLightColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogLightColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogLightColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide:
                const BorderSide(color: MatchLogLightColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide: const BorderSide(color: MatchLogLightColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide: const BorderSide(
              color: MatchLogLightColors.error,
              width: 2,
            ),
          ),
          hintStyle: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogLightColors.textTertiary,
          ),
          labelStyle: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
          errorStyle: MatchLogTypography.bodySmall.copyWith(
            color: MatchLogLightColors.error,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: MatchLogLightColors.surface,
          selectedColor: MatchLogLightColors.primaryLight,
          disabledColor: MatchLogLightColors.surfaceBorder,
          checkmarkColor: MatchLogLightColors.primary,
          showCheckmark: false,
          labelStyle: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          side: const BorderSide(color: MatchLogLightColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedFull,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogLightColors.primaryLight;
            }
            return MatchLogLightColors.surface;
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: MatchLogLightColors.surfaceBorder,
          thickness: 1,
          space: 0,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: MatchLogLightColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedLg,
          ),
          titleTextStyle: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          contentTextStyle: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: MatchLogLightColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MatchLogSpacing.radiusLg),
            ),
          ),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: MatchLogLightColors.textSecondary,
          titleTextStyle: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          subtitleTextStyle: MatchLogTypography.bodySmall.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogLightColors.primary;
            }
            return MatchLogLightColors.textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogLightColors.primarySurface;
            }
            return MatchLogLightColors.surfaceBorder;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: MatchLogLightColors.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: MatchLogLightColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: CircleBorder(),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: MatchLogLightColors.textPrimary,
          contentTextStyle: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogLightColors.surface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
          ),
          behavior: SnackBarBehavior.floating,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: MatchLogLightColors.primary,
          unselectedLabelColor: MatchLogLightColors.textTertiary,
          indicatorColor: MatchLogLightColors.primary,
          labelStyle: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogLightColors.primary,
          ),
          unselectedLabelStyle: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogLightColors.textTertiary,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: MatchLogTypography.headlineXL.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          displayMedium: MatchLogTypography.headlineLarge.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          displaySmall: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          headlineMedium: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          headlineSmall: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          titleLarge: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          titleMedium: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          titleSmall: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
          bodyLarge: MatchLogTypography.bodyLarge.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
          bodyMedium: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
          bodySmall: MatchLogTypography.bodySmall.copyWith(
            color: MatchLogLightColors.textTertiary,
          ),
          labelLarge: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogLightColors.textPrimary,
          ),
          labelSmall: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogLightColors.textSecondary,
          ),
        ),
      );

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
          outline: MatchLogColors.surfaceBorder,
          outlineVariant: MatchLogColors.surfaceBorder,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MatchLogColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogColors.textPrimary,
          ),
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
            backgroundColor: MatchLogColors.textPrimary,
            foregroundColor: MatchLogColors.background,
            disabledBackgroundColor: MatchLogColors.surfaceBorder,
            disabledForegroundColor: MatchLogColors.textDisabled,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogColors.background,
            ),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MatchLogColors.primary,
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogColors.primary,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: MatchLogColors.textPrimary,
            side: const BorderSide(color: MatchLogColors.surfaceBorder),
            backgroundColor: MatchLogColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: MatchLogSpacing.roundedMd,
            ),
            textStyle: MatchLogTypography.labelLarge.copyWith(
              color: MatchLogColors.textPrimary,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MatchLogColors.surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide: const BorderSide(color: MatchLogColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: MatchLogSpacing.roundedMd,
            borderSide: const BorderSide(color: MatchLogColors.surfaceBorder),
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
            borderSide: const BorderSide(color: MatchLogColors.error, width: 2),
          ),
          hintStyle: MatchLogTypography.bodyMedium
              .copyWith(color: MatchLogColors.textTertiary),
          labelStyle: MatchLogTypography.labelSmall
              .copyWith(color: MatchLogColors.textSecondary),
          errorStyle: MatchLogTypography.bodySmall
              .copyWith(color: MatchLogColors.error),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: MatchLogColors.surfaceElevated,
          selectedColor: MatchLogColors.primarySurface,
          disabledColor: MatchLogColors.surfaceBorder,
          checkmarkColor: MatchLogColors.primary,
          showCheckmark: false,
          labelStyle: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          side: const BorderSide(color: MatchLogColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedFull,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchLogColors.primarySurface;
            }
            return MatchLogColors.surfaceElevated;
          }),
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
          titleTextStyle: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          contentTextStyle: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogColors.textSecondary,
          ),
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
          subtitleTextStyle: MatchLogTypography.bodySmall.copyWith(
            color: MatchLogColors.textSecondary,
          ),
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
          labelStyle: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogColors.primary,
          ),
          unselectedLabelStyle: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogColors.textTertiary,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: MatchLogTypography.headlineXL.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          displayMedium: MatchLogTypography.headlineLarge.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          displaySmall: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          headlineMedium: MatchLogTypography.headlineMedium.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          headlineSmall: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          titleLarge: MatchLogTypography.headlineSmall.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          titleMedium: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          titleSmall: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogColors.textSecondary,
          ),
          bodyLarge: MatchLogTypography.bodyLarge.copyWith(
            color: MatchLogColors.textSecondary,
          ),
          bodyMedium: MatchLogTypography.bodyMedium.copyWith(
            color: MatchLogColors.textSecondary,
          ),
          bodySmall: MatchLogTypography.bodySmall.copyWith(
            color: MatchLogColors.textTertiary,
          ),
          labelLarge: MatchLogTypography.labelLarge.copyWith(
            color: MatchLogColors.textPrimary,
          ),
          labelSmall: MatchLogTypography.labelSmall.copyWith(
            color: MatchLogColors.textSecondary,
          ),
        ),
      );
}
