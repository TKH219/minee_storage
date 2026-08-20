import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/error_aware_container.dart';

import '../../support/localization_test_harness.dart';

void main() {
  Widget host(Widget child) => Theme(data: AppTheme.light(), child: Scaffold(body: child));

  testWidgets('empty view falls back to translated copy', (tester) async {
    await pumpLocalized(tester, host(const EmptyView()), locale: viLocale);
    expect(find.text('Chưa có gì ở đây'), findsOneWidget);
  });

  testWidgets('empty view still honours an explicit title', (tester) async {
    await pumpLocalized(tester, host(const EmptyView(title: 'Kệ hàng của bạn đang trống')));
    expect(find.text('Kệ hàng của bạn đang trống'), findsOneWidget);
  });

  testWidgets('error container translates its heading and retry label', (tester) async {
    await pumpLocalized(
      tester,
      host(ErrorAwareContainer(message: 'x', onRetry: () {})),
      locale: viLocale,
    );
    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
