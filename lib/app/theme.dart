import 'package:flutter/material.dart';

import '../shared/design_system/mameroom_design_system.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const mameroom = MameroomTheme.light;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: MameroomColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: MameroomColors.primary,
          secondary: MameroomColors.primarySoft,
          surface: MameroomColors.surface,
          onSurface: MameroomColors.textPrimary,
          outline: MameroomColors.border,
          error: MameroomColors.error,
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MameroomRadius.medium),
      borderSide: const BorderSide(color: MameroomColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MameroomColors.surfaceMuted,
      fontFamily: MameroomTypography.fontFamily,
      textTheme: MameroomTypography.textTheme,
      extensions: const [mameroom],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: MameroomColors.surfaceMuted,
        foregroundColor: MameroomColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MameroomColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MameroomSpacing.md,
          vertical: MameroomSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MameroomColors.gray300),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: MameroomColors.error),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: MameroomColors.primary,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MameroomColors.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return MameroomColors.primaryPressed;
            }
            return MameroomColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(MameroomColors.white),
          textStyle: const WidgetStatePropertyAll(MameroomTypography.button),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MameroomRadius.medium),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
          foregroundColor: const WidgetStatePropertyAll(
            MameroomColors.textPrimary,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: MameroomColors.border),
          ),
          textStyle: const WidgetStatePropertyAll(MameroomTypography.button),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MameroomRadius.medium),
            ),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(MameroomTypography.button),
        ),
      ),
      cardTheme: CardThemeData(
        color: MameroomColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MameroomRadius.card),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: MameroomColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MameroomRadius.modal),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MameroomColors.surfaceMuted,
        selectedColor: MameroomColors.primaryMist,
        disabledColor: MameroomColors.gray100,
        labelStyle: MameroomTypography.caption.copyWith(
          color: MameroomColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: MameroomTypography.caption.copyWith(
          color: MameroomColors.primary,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: MameroomColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MameroomRadius.pill),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: MameroomColors.primary,
        unselectedItemColor: MameroomColors.textMuted,
        backgroundColor: MameroomColors.surface,
        selectedLabelStyle: MameroomTypography.caption,
        unselectedLabelStyle: MameroomTypography.caption,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MameroomColors.surface,
        indicatorColor: MameroomColors.primaryMist,
        labelTextStyle: WidgetStatePropertyAll(
          MameroomTypography.caption.copyWith(
            color: MameroomColors.textPrimary,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MameroomColors.primary,
        linearTrackColor: MameroomColors.primaryMist,
        circularTrackColor: MameroomColors.primaryMist,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MameroomColors.primary;
          }
          return MameroomColors.gray500;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return MameroomColors.primary;
          }
          return MameroomColors.surface;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MameroomRadius.r4),
        ),
      ),
    );
  }
}
