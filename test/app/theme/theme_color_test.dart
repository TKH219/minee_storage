import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme_color.dart';

void main() {
  test('light role tokens match the design', () {
    final c = ColorThemeExt.light();
    expect(c.fillPrimary, const Color(0xFFD4F5FC));
    expect(c.onPrimary, const Color(0xFF1F2328));
    expect(c.inkPrimary, const Color(0xFF0F72B0));
    expect(c.tintPrimary, const Color(0xFFF0FFFF));
    expect(c.highlight, const Color(0xFFD4F5FC));
    expect(c.barSurface, const Color(0xFFFFFFFF));
    expect(c.scrim, const Color(0x6B1F2328));
    expect(c.shimmer, const Color(0x9EFFFFFF));
    expect(c.orange0, const Color(0xFFFFF3E4));
    expect(c.orange6, const Color(0xFFA85506));
  });

  test('dark role tokens invert rather than mirror', () {
    final c = ColorThemeExt.dark();
    expect(c.fillPrimary, const Color(0xFF7FDDF2));
    expect(c.onPrimary, const Color(0xFF0D1117));
    expect(c.inkPrimary, const Color(0xFF7FDDF2));
    expect(c.tintPrimary, const Color(0xFF0E3A47));
    expect(c.highlight, const Color(0xFF0E3A47));
    expect(c.barSurface, const Color(0xFF1E252E));
    expect(c.scrim, const Color(0x99000000));
    expect(c.shimmer, const Color(0x1AFFFFFF));
    expect(c.orange0, const Color(0xFF3A2A14));
    expect(c.orange6, const Color(0xFFE8944A));
  });

  test('elevation is the design two-layer shadow', () {
    final c = ColorThemeExt.light();
    expect(c.elevation, hasLength(2));
    expect(c.elevation.first.offset, const Offset(0, 2));
    expect(c.elevation.first.blurRadius, 6);
    expect(c.elevation.last.offset, const Offset(0, 10));
    expect(c.elevation.last.blurRadius, 28);
  });

  test('copyWith and lerp carry the new tokens', () {
    final light = ColorThemeExt.light();
    expect(light.copyWith(inkPrimary: const Color(0xFF123456)).inkPrimary,
        const Color(0xFF123456));
    expect(light.lerp(ColorThemeExt.dark(), 1).barSurface,
        ColorThemeExt.dark().barSurface);
  });
}
