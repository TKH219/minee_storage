import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_review_state.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/features/settings/widgets/logout_dialog.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const signedIn = UserEntity(
  id: 'uid-1',
  email: 'maya@northsidegrocers.com',
  fullName: 'Northside Grocers',
);

void main() {
  late SharedPreferences prefs;
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = FakeAuthRepository(user: signedIn);
  });

  void useTallFrame(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpSettings(WidgetTester tester, {Locale locale = enLocale}) async {
    useTallFrame(tester);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);

    await pumpLocalizedApp(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: Theme(
          data: AppTheme.light(),
          child: ScaffoldMessenger(
            key: snackbarKey,
            child: const SettingsPage(),
          ),
        ),
      ),
      locale: locale,
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks before it acts, and names the account', (tester) async {
    await pumpSettings(tester);
    await openDialog(tester);

    expect(find.byType(LogoutDialog), findsOneWidget);
    expect(find.text('Log out?'), findsOneWidget);
    expect(
      find.textContaining("You'll need your email and password"),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LogoutDialog),
        matching: find.textContaining('maya@northsidegrocers.com'),
      ),
      findsOneWidget,
      reason: 'the dialog names which account it is about to sign out',
    );
  });

  testWidgets('Stay dismisses and touches nothing', (tester) async {
    await pumpSettings(tester);
    await openDialog(tester);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutDialog), findsNothing);
    expect(auth.calls, isNot(contains('signOut')));
  });

  testWidgets('Log out signs out exactly once', (tester) async {
    await pumpSettings(tester);
    await openDialog(tester);

    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(auth.calls.where((call) => call == 'signOut'), hasLength(1));
  });

  testWidgets('no tab state survives the way out', (tester) async {
    await pumpSettings(tester);

    // Something is in flight before signing out — a half-built sale.
    container.read(saleCartStateProvider.notifier).addLine(
      SaleDraftLine(
        productId: 'p1',
        productName: 'Olive oil 1L',
        unit: ProductUnit.litre,
        quantity: Decimal.one,
        unitSellPrice: d('20.00'),
        allocations: [
          SaleAllocation(
            batchId: 'b1',
            batchCode: '#B-0001',
            quantity: Decimal.one,
            unitCost: d('11.50'),
          ),
        ],
      ),
    );
    expect(container.read(saleCartStateProvider).draft.lines, hasLength(1));

    await openDialog(tester);
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(
      container.read(saleCartStateProvider).draft.lines,
      isEmpty,
      reason: 'the next session must not inherit the last one\'s basket',
    );
    expect(container.read(saleReviewStateProvider).sale, isNull);
  });

  testWidgets('a failure keeps the user signed in and says so', (tester) async {
    auth.error = Exception('offline');

    await pumpSettings(tester);
    await openDialog(tester);

    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('the dialog is drawn at the design\'s radius', (tester) async {
    await pumpSettings(tester);
    await openDialog(tester);

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(LogoutDialog.radius));
    expect(LogoutDialog.radius, 16);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSettings(tester, locale: viLocale);

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất?'), findsOneWidget);
    expect(find.text('Ở lại'), findsOneWidget);
    expect(find.textContaining('settings.'), findsNothing);
  });
}
