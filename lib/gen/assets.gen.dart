// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsAnimationsGen {
  const $AssetsAnimationsGen();

  /// File path: assets/animations/check.json
  String get check => 'assets/animations/check.json';

  /// File path: assets/animations/dots.json
  String get dots => 'assets/animations/dots.json';

  /// File path: assets/animations/scan.json
  String get scan => 'assets/animations/scan.json';

  /// File path: assets/animations/spinner.json
  String get spinner => 'assets/animations/spinner.json';

  /// List of all assets
  List<String> get values => [check, dots, scan, spinner];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/ic_apple.svg
  SvgGenImage get icApple => const SvgGenImage('assets/icons/ic_apple.svg');

  /// File path: assets/icons/ic_arrow_back.svg
  SvgGenImage get icArrowBack =>
      const SvgGenImage('assets/icons/ic_arrow_back.svg');

  /// File path: assets/icons/ic_checked.svg
  SvgGenImage get icChecked => const SvgGenImage('assets/icons/ic_checked.svg');

  /// File path: assets/icons/ic_close.svg
  SvgGenImage get icClose => const SvgGenImage('assets/icons/ic_close.svg');

  /// File path: assets/icons/ic_close_green.svg
  SvgGenImage get icCloseGreen =>
      const SvgGenImage('assets/icons/ic_close_green.svg');

  /// File path: assets/icons/ic_edit.svg
  SvgGenImage get icEdit => const SvgGenImage('assets/icons/ic_edit.svg');

  /// File path: assets/icons/ic_google.svg
  SvgGenImage get icGoogle => const SvgGenImage('assets/icons/ic_google.svg');

  /// File path: assets/icons/ic_home_empty.svg
  SvgGenImage get icHomeEmpty =>
      const SvgGenImage('assets/icons/ic_home_empty.svg');

  /// File path: assets/icons/ic_logout.svg
  SvgGenImage get icLogout => const SvgGenImage('assets/icons/ic_logout.svg');

  /// File path: assets/icons/ic_password_hide.svg
  SvgGenImage get icPasswordHide =>
      const SvgGenImage('assets/icons/ic_password_hide.svg');

  /// File path: assets/icons/ic_password_show.svg
  SvgGenImage get icPasswordShow =>
      const SvgGenImage('assets/icons/ic_password_show.svg');

  /// File path: assets/icons/ic_search.svg
  SvgGenImage get icSearch => const SvgGenImage('assets/icons/ic_search.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    icApple,
    icArrowBack,
    icChecked,
    icClose,
    icCloseGreen,
    icEdit,
    icGoogle,
    icHomeEmpty,
    icLogout,
    icPasswordHide,
    icPasswordShow,
    icSearch,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/.gitkeep
  String get aGitkeep => 'assets/images/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

class $AssetsTranslationsGen {
  const $AssetsTranslationsGen();

  /// File path: assets/translations/en.json
  String get en => 'assets/translations/en.json';

  /// File path: assets/translations/vi.json
  String get vi => 'assets/translations/vi.json';

  /// List of all assets
  List<String> get values => [en, vi];
}

abstract final class Assets {
  static const $AssetsAnimationsGen animations = $AssetsAnimationsGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsTranslationsGen translations = $AssetsTranslationsGen();
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
