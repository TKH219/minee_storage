import 'package:flutter/material.dart';

import 'package:mine_storage/gen/fonts.gen.dart';

import 'app_colors.dart';

/// Typography tokens, resolved per brightness.
///
/// Read them with `context.textStyles.sansBody`. Every style inherits
/// [defaultTextColor], so a style used in dark mode is already legible without
/// the call site overriding the colour.
@immutable
class TextThemeExt extends ThemeExtension<TextThemeExt> {
  const TextThemeExt({required this.defaultTextColor});

  factory TextThemeExt.light() => const TextThemeExt(
    defaultTextColor: AppColors.neutral9Light,
  );

  factory TextThemeExt.dark() => const TextThemeExt(
    defaultTextColor: AppColors.neutral9Dark,
  );

  final Color defaultTextColor;

  /// DM Sans
  TextStyle get sansTitleHeading1 => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 3 / 2,
  );

  TextStyle get sansTitleHeading2 => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 3 / 2,
  );

  TextStyle get sansTitleHeading3 => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 3 / 2,
  );

  TextStyle get sansBodyBold => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 3 / 2,
  );

  TextStyle get sansBody => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 3 / 2,
  );

  TextStyle get sansCaption => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 3 / 2,
  );

  TextStyle get sansTableHeader => TextStyle(
    fontFamily: FontFamily.dMSans,
    color: defaultTextColor,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 3 / 2,
  );

  /// DM Mono
  TextStyle get monoBody => TextStyle(
    fontFamily: FontFamily.dMMono,
    color: defaultTextColor,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 3 / 2,
  );

  TextStyle get monoTableHeader => TextStyle(
    fontFamily: FontFamily.dMMono,
    color: defaultTextColor,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 3 / 2,
  );

  TextStyle get monoItalic => TextStyle(
    fontFamily: FontFamily.dMMono,
    color: defaultTextColor,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 3 / 2,
  );

  /// Pinyinok
  TextStyle get pinyinokTitleHeading1 => TextStyle(
    fontFamily: FontFamily.pinyinok,
    color: defaultTextColor,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 3 / 2,
  );

  TextStyle get pinyinokBody => TextStyle(
    fontFamily: FontFamily.pinyinok,
    color: defaultTextColor,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 3 / 2,
  );

  @override
  TextThemeExt copyWith({Color? defaultTextColor}) {
    return TextThemeExt(defaultTextColor: defaultTextColor ?? this.defaultTextColor);
  }

  @override
  TextThemeExt lerp(covariant TextThemeExt? other, double t) {
    if (other == null) return this;
    return TextThemeExt(
      defaultTextColor: Color.lerp(defaultTextColor, other.defaultTextColor, t)!,
    );
  }
}
