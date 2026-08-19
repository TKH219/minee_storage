import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/app_colors.dart';

void main() {
  test('primary ramp is the cyan system from the design', () {
    expect(AppColors.primary0Light, const Color(0xFFF0FFFF));
    expect(AppColors.primary1Light, const Color(0xFFD4F5FC));
    expect(AppColors.primary2Light, const Color(0xFFB1EDFF));
    expect(AppColors.primary3Light, const Color(0xFF87CEFA));
    expect(AppColors.primary4Light, const Color(0xFF0F72B0));
    expect(AppColors.primary5Light, const Color(0xFF08506F));

    expect(AppColors.primary0Dark, const Color(0xFF0C2A33));
    expect(AppColors.primary1Dark, const Color(0xFF0E3A47));
    expect(AppColors.primary2Dark, const Color(0xFF16505F));
    expect(AppColors.primary3Dark, const Color(0xFF4FB4DC));
    expect(AppColors.primary4Dark, const Color(0xFF7FDDF2));
    expect(AppColors.primary5Dark, const Color(0xFFD4F5FC));
  });

  test('expiring-soon badge tokens exist', () {
    expect(AppColors.orange0Light, const Color(0xFFFFF3E4));
    expect(AppColors.orange6Light, const Color(0xFFA85506));
    expect(AppColors.orange0Dark, const Color(0xFF3A2A14));
    expect(AppColors.orange6Dark, const Color(0xFFE8944A));
  });

  test('neutral and semantic ramps are untouched', () {
    expect(AppColors.neutral0Light, const Color(0xFFFFFFFF));
    expect(AppColors.neutral9Light, const Color(0xFF1F2328));
    expect(AppColors.neutral0Dark, const Color(0xFF0D1117));
    expect(AppColors.green5Light, const Color(0xFF1A7F5A));
    expect(AppColors.red5Light, const Color(0xFFC93A28));
    expect(AppColors.orange5Light, const Color(0xFFB45C06));
    expect(AppColors.blue5Light, const Color(0xFF1D6AE0));
  });
}
