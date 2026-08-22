import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/create_store/pages/create_store_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/avatar_picker.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const _categories = [
  StoreCategory(
    code: 'grocery', nameVi: 'Tạp hóa', nameEn: 'Grocery', icon: 'basket', sortOrder: 10,
  ),
  StoreCategory(
    code: 'cafe', nameVi: 'Quán cà phê', nameEn: 'Cafe', icon: 'cafe', sortOrder: 40,
  ),
];

Widget host({
  Brightness brightness = Brightness.light,
  FakeStoreRepository? stores,
}) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            user: const UserEntity(id: 'uid-1', email: 'a@b.com', fullName: 'Maya'),
          ),
        ),
        storeRepositoryProvider.overrideWithValue(
          stores ??
              FakeStoreRepository(
                categoryList: _categories,
                currencyList: const [
                  Currency.vnd,
                  Currency(code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20),
                ],
              ),
        ),
        mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
        routerProvider.overrideWithValue(buildTestRouter()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
        home: const CreateStorePage(),
      ),
    );

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('carries the design copy', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Set up your shop'), findsOneWidget);
    expect(find.text('Shop name'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Create shop'), findsOneWidget);
  });

  testWidgets('currency reads VND before anything is chosen', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.textContaining('VND'), findsOneWidget);
  });

  testWidgets('category shows a prompt until one is chosen, then the name', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);

    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cafe'));
    await tester.pumpAndSettle();

    expect(find.text('Cafe'), findsOneWidget);
    expect(find.text('Choose a category'), findsNothing);
  });

  testWidgets('Create is held until both required fields are filled', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Tạp hóa Linh');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grocery'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('a failed category load offers a retry', (tester) async {
    final stores = FakeStoreRepository(
      categoryList: _categories,
      error: const NetworkException(),
    );
    await tester.pumpWidget(host(stores: stores));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);

    stores.error = null;
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('the logo well is the square variant', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(
      tester.widget<AvatarPicker>(find.byType(AvatarPicker)).shape,
      AvatarPickerShape.rounded,
    );
  });

  testWidgets('the screen cannot be popped', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(tester.widget<PopScope>(find.byType(PopScope).first).canPop, isFalse);
  });

  testWidgets('renders in dark without throwing', (tester) async {
    await tester.pumpWidget(host(brightness: Brightness.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the currency picker lists what the table returned', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('VND'));
    await tester.pumpAndSettle();

    expect(find.text('Which currency?'), findsOneWidget);
    expect(find.textContaining('USD'), findsOneWidget);

    await tester.tap(find.textContaining('USD'));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'USD  $'), findsOneWidget);
  });
}
