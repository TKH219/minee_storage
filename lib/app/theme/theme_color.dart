import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colour tokens, resolved per brightness.
///
/// Read them from a widget with `context.colors.neutral9`. Both [copyWith] and
/// [lerp] are fully implemented so theme switches animate rather than snap.
@immutable
class ColorThemeExt extends ThemeExtension<ColorThemeExt> {
  const ColorThemeExt({
    required this.brightness,
    required this.white,
    required this.black,
    required this.primary0,
    required this.primary1,
    required this.primary2,
    required this.primary3,
    required this.primary4,
    required this.primary5,
    required this.neutral0,
    required this.neutral1,
    required this.neutral2,
    required this.neutral3,
    required this.neutral4,
    required this.neutral5,
    required this.neutral6,
    required this.neutral7,
    required this.neutral8,
    required this.neutral9,
    required this.green0,
    required this.green1,
    required this.green5,
    required this.red0,
    required this.red5,
    required this.orange5,
    required this.blue5,
  });

  factory ColorThemeExt.light() {
    return const ColorThemeExt(
      brightness: Brightness.light,
      white: AppColors.white,
      black: AppColors.black,
      primary0: AppColors.primary0Light,
      primary1: AppColors.primary1Light,
      primary2: AppColors.primary2Light,
      primary3: AppColors.primary3Light,
      primary4: AppColors.primary4Light,
      primary5: AppColors.primary5Light,
      neutral0: AppColors.neutral0Light,
      neutral1: AppColors.neutral1Light,
      neutral2: AppColors.neutral2Light,
      neutral3: AppColors.neutral3Light,
      neutral4: AppColors.neutral4Light,
      neutral5: AppColors.neutral5Light,
      neutral6: AppColors.neutral6Light,
      neutral7: AppColors.neutral7Light,
      neutral8: AppColors.neutral8Light,
      neutral9: AppColors.neutral9Light,
      green0: AppColors.green0Light,
      green1: AppColors.green1Light,
      green5: AppColors.green5Light,
      red0: AppColors.red0Light,
      red5: AppColors.red5Light,
      orange5: AppColors.orange5Light,
      blue5: AppColors.blue5Light,
    );
  }

  factory ColorThemeExt.dark() {
    return const ColorThemeExt(
      brightness: Brightness.dark,
      white: AppColors.white,
      black: AppColors.black,
      primary0: AppColors.primary0Dark,
      primary1: AppColors.primary1Dark,
      primary2: AppColors.primary2Dark,
      primary3: AppColors.primary3Dark,
      primary4: AppColors.primary4Dark,
      primary5: AppColors.primary5Dark,
      neutral0: AppColors.neutral0Dark,
      neutral1: AppColors.neutral1Dark,
      neutral2: AppColors.neutral2Dark,
      neutral3: AppColors.neutral3Dark,
      neutral4: AppColors.neutral4Dark,
      neutral5: AppColors.neutral5Dark,
      neutral6: AppColors.neutral6Dark,
      neutral7: AppColors.neutral7Dark,
      neutral8: AppColors.neutral8Dark,
      neutral9: AppColors.neutral9Dark,
      green0: AppColors.green0Dark,
      green1: AppColors.green1Dark,
      green5: AppColors.green5Dark,
      red0: AppColors.red0Dark,
      red5: AppColors.red5Dark,
      orange5: AppColors.orange5Dark,
      blue5: AppColors.blue5Dark,
    );
  }

  final Brightness brightness;

  final Color white;
  final Color black;

  final Color primary0;
  final Color primary1;
  final Color primary2;
  final Color primary3;
  final Color primary4;
  final Color primary5;

  final Color neutral0;
  final Color neutral1;
  final Color neutral2;
  final Color neutral3;
  final Color neutral4;
  final Color neutral5;
  final Color neutral6;
  final Color neutral7;
  final Color neutral8;
  final Color neutral9;

  final Color green0;
  final Color green1;
  final Color green5;

  final Color red0;
  final Color red5;

  final Color orange5;
  final Color blue5;

  bool get isDark => brightness == Brightness.dark;

  @override
  ColorThemeExt copyWith({
    Brightness? brightness,
    Color? white,
    Color? black,
    Color? primary0,
    Color? primary1,
    Color? primary2,
    Color? primary3,
    Color? primary4,
    Color? primary5,
    Color? neutral0,
    Color? neutral1,
    Color? neutral2,
    Color? neutral3,
    Color? neutral4,
    Color? neutral5,
    Color? neutral6,
    Color? neutral7,
    Color? neutral8,
    Color? neutral9,
    Color? green0,
    Color? green1,
    Color? green5,
    Color? red0,
    Color? red5,
    Color? orange5,
    Color? blue5,
  }) {
    return ColorThemeExt(
      brightness: brightness ?? this.brightness,
      white: white ?? this.white,
      black: black ?? this.black,
      primary0: primary0 ?? this.primary0,
      primary1: primary1 ?? this.primary1,
      primary2: primary2 ?? this.primary2,
      primary3: primary3 ?? this.primary3,
      primary4: primary4 ?? this.primary4,
      primary5: primary5 ?? this.primary5,
      neutral0: neutral0 ?? this.neutral0,
      neutral1: neutral1 ?? this.neutral1,
      neutral2: neutral2 ?? this.neutral2,
      neutral3: neutral3 ?? this.neutral3,
      neutral4: neutral4 ?? this.neutral4,
      neutral5: neutral5 ?? this.neutral5,
      neutral6: neutral6 ?? this.neutral6,
      neutral7: neutral7 ?? this.neutral7,
      neutral8: neutral8 ?? this.neutral8,
      neutral9: neutral9 ?? this.neutral9,
      green0: green0 ?? this.green0,
      green1: green1 ?? this.green1,
      green5: green5 ?? this.green5,
      red0: red0 ?? this.red0,
      red5: red5 ?? this.red5,
      orange5: orange5 ?? this.orange5,
      blue5: blue5 ?? this.blue5,
    );
  }

  @override
  ColorThemeExt lerp(covariant ColorThemeExt? other, double t) {
    if (other == null) return this;
    return ColorThemeExt(
      brightness: t < 0.5 ? brightness : other.brightness,
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      primary0: Color.lerp(primary0, other.primary0, t)!,
      primary1: Color.lerp(primary1, other.primary1, t)!,
      primary2: Color.lerp(primary2, other.primary2, t)!,
      primary3: Color.lerp(primary3, other.primary3, t)!,
      primary4: Color.lerp(primary4, other.primary4, t)!,
      primary5: Color.lerp(primary5, other.primary5, t)!,
      neutral0: Color.lerp(neutral0, other.neutral0, t)!,
      neutral1: Color.lerp(neutral1, other.neutral1, t)!,
      neutral2: Color.lerp(neutral2, other.neutral2, t)!,
      neutral3: Color.lerp(neutral3, other.neutral3, t)!,
      neutral4: Color.lerp(neutral4, other.neutral4, t)!,
      neutral5: Color.lerp(neutral5, other.neutral5, t)!,
      neutral6: Color.lerp(neutral6, other.neutral6, t)!,
      neutral7: Color.lerp(neutral7, other.neutral7, t)!,
      neutral8: Color.lerp(neutral8, other.neutral8, t)!,
      neutral9: Color.lerp(neutral9, other.neutral9, t)!,
      green0: Color.lerp(green0, other.green0, t)!,
      green1: Color.lerp(green1, other.green1, t)!,
      green5: Color.lerp(green5, other.green5, t)!,
      red0: Color.lerp(red0, other.red0, t)!,
      red5: Color.lerp(red5, other.red5, t)!,
      orange5: Color.lerp(orange5, other.orange5, t)!,
      blue5: Color.lerp(blue5, other.blue5, t)!,
    );
  }
}
