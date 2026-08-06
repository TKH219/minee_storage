import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mine_storage/gen/assets.gen.dart';
import 'package:mine_storage/gen/fonts.gen.dart';

import 'theme_color.dart';
import 'theme_text.dart';

export 'theme_color.dart';
export 'theme_mode_provider.dart';
export 'theme_text.dart';

extension BuildContextThemeExt on BuildContext {
  ColorThemeExt get colors => Theme.of(this).extension<ColorThemeExt>()!;

  TextThemeExt get textStyles => Theme.of(this).extension<TextThemeExt>()!;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

extension SvgGenImageExt on SvgGenImage {
  SvgPicture tinted(Color color, {double? width, double? height}) {
    // `this.` is required: flutter_svg exports a top-level `svg` object that
    // would otherwise win name resolution over this extension's target method.
    return this.svg(
      width: width,
      height: height,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

abstract class AppTheme {
  static ThemeData light() => _build(
    colors: ColorThemeExt.light(),
    texts: TextThemeExt.light(),
  );

  static ThemeData dark() => _build(
    colors: ColorThemeExt.dark(),
    texts: TextThemeExt.dark(),
  );

  /// Both brightnesses are assembled here so a change to component styling can
  /// never drift between light and dark.
  static ThemeData _build({
    required ColorThemeExt colors,
    required TextThemeExt texts,
  }) {
    final colorScheme = ColorScheme(
      brightness: colors.brightness,
      primary: colors.primary4,
      onPrimary: colors.isDark ? colors.neutral0 : colors.white,
      primaryContainer: colors.primary1,
      onPrimaryContainer: colors.isDark ? colors.neutral9 : colors.primary5,
      secondary: colors.blue5,
      onSecondary: colors.white,
      surface: colors.neutral0,
      onSurface: colors.neutral9,
      surfaceContainerHighest: colors.neutral2,
      onSurfaceVariant: colors.neutral6,
      error: colors.red5,
      onError: colors.white,
      errorContainer: colors.red0,
      onErrorContainer: colors.isDark ? colors.neutral9 : colors.red5,
      outline: colors.neutral4,
      outlineVariant: colors.neutral3,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.neutral1,
      fontFamily: FontFamily.dMSans,
      extensions: [colors, texts],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.neutral0,
        foregroundColor: colors.neutral9,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: texts.sansTitleHeading3,
      ),
      dividerTheme: DividerThemeData(color: colors.neutral3, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: colors.neutral0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.neutral3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary4,
          foregroundColor: colors.isDark ? colors.neutral0 : colors.white,
          disabledBackgroundColor: colors.neutral3,
          disabledForegroundColor: colors.neutral5,
          minimumSize: const Size.fromHeight(52),
          textStyle: texts.sansBodyBold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary4,
          textStyle: texts.sansBodyBold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.neutral0,
        hintStyle: texts.sansBody.copyWith(color: colors.neutral5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(colors.neutral3),
        enabledBorder: _inputBorder(colors.neutral3),
        focusedBorder: _inputBorder(colors.primary4, width: 1.5),
        errorBorder: _inputBorder(colors.red5),
        focusedErrorBorder: _inputBorder(colors.red5, width: 1.5),
        errorStyle: texts.sansCaption.copyWith(color: colors.red5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: texts.sansBody.copyWith(color: colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary4),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.neutral0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: texts.sansBodyBold,
        subtitleTextStyle: texts.sansBody.copyWith(color: colors.neutral6),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
