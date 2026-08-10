import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/home/pages/home_page.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/shared/ui/theme_mode_button.dart';

import '../support/auth_test_harness.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpHome(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          routerProvider.overrideWithValue(buildTestRouter()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomePage(),
        ),
      ),
    );
  }

  testWidgets('renders the Home placeholder', (tester) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Home is not built yet'), findsOneWidget);
  });

  testWidgets('offers the theme toggle', (tester) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ThemeModeButton), findsOneWidget);
  });
}