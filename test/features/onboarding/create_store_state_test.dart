import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/create_store/states/create_store_state.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/providers.dart';

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
    code: 'other', nameVi: 'Khác', nameEn: 'Other', icon: 'other', sortOrder: 130,
  ),
];

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({
    ProviderContainer container,
    FakeStoreRepository stores,
    FakeMediaRepository media,
    FakeAuthRepository auth,
    GoRouter router,
  })
  build({FakeStoreRepository? stores, FakeMediaRepository? media}) {
    final router = buildTestRouter();
    final storeRepository = stores ?? FakeStoreRepository(categoryList: _categories);
    final mediaRepository = media ?? FakeMediaRepository();
    final auth = FakeAuthRepository(
      user: const UserEntity(id: 'uid-1', email: 'a@b.com', fullName: 'Maya'),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        storeRepositoryProvider.overrideWithValue(storeRepository),
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(createStoreStateProvider, (_, _) {});
    return (
      container: container,
      stores: storeRepository,
      media: mediaRepository,
      auth: auth,
      router: router,
    );
  }

  test('currency defaults to VND', () {
    final t = build();

    expect(t.container.read(createStoreStateProvider).currencyCode, 'VND');
  });

  test('loadCategories fills the list', () async {
    final t = build();

    await t.container.read(createStoreStateProvider.notifier).loadCategories();

    expect(t.container.read(createStoreStateProvider).categories, _categories);
  });

  test('the currency list is read from the repository, not hardcoded', () async {
    const usd = Currency(code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);
    final t = build(
      stores: FakeStoreRepository(
        categoryList: _categories,
        currencyList: const [Currency.vnd, usd],
      ),
    );

    await t.container.read(createStoreStateProvider.notifier).loadCategories();

    expect(t.stores.calls, contains('currencies'));
    expect(t.container.read(createStoreStateProvider).currencies, [Currency.vnd, usd]);
  });

  test('the selected currency resolves against the loaded list', () async {
    const usd = Currency(code: 'USD', symbol: r'$', decimals: 2, sortOrder: 20);
    final t = build(
      stores: FakeStoreRepository(
        categoryList: _categories,
        currencyList: const [Currency.vnd, usd],
      ),
    );
    final notifier = t.container.read(createStoreStateProvider.notifier);
    await notifier.loadCategories();

    notifier.updateCurrency('USD');

    expect(t.container.read(createStoreStateProvider).currency, usd);
  });

  test('before the list loads, the currency shows the VND default', () {
    final t = build();

    expect(t.container.read(createStoreStateProvider).currencies, isEmpty);
    expect(t.container.read(createStoreStateProvider).currency, Currency.vnd);
  });

  test('a failed load leaves both lists empty and recoverable', () async {
    final stores = FakeStoreRepository(
      categoryList: _categories,
      currencyList: const [Currency.vnd],
      error: const NetworkException(),
    );
    final t = build(stores: stores);
    final notifier = t.container.read(createStoreStateProvider.notifier);

    await notifier.loadCategories();
    expect(t.container.read(createStoreStateProvider).isError, isTrue);
    expect(t.container.read(createStoreStateProvider).currencies, isEmpty);

    stores.error = null;
    await notifier.loadCategories();
    expect(t.container.read(createStoreStateProvider).currencies, isNotEmpty);
  });

  test('submit creates the shop, stores the active id and reaches the dashboard', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('Tạp hóa Linh')
      ..updateCategory('grocery');

    await notifier.submit();

    expect(t.stores.calls, contains('create:Tạp hóa Linh:grocery:VND'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(OnboardingResolver.activeStoreKey), isNotNull);
    expect(currentPath(t.router), '/dashboard');
  });

  test('submit stamps onboarding as complete', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('S')
      ..updateCategory('other');

    await notifier.submit();

    expect(t.auth.calls, contains('completeOnboarding'));
  });

  test('a name or category is required before submit', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier);

    await notifier.submit();
    expect(t.stores.calls.where((c) => c.startsWith('create')), isEmpty);

    notifier.updateName('S');
    await notifier.submit();
    expect(t.stores.calls.where((c) => c.startsWith('create')), isEmpty);

    notifier.updateCategory('other');
    await notifier.submit();
    expect(t.stores.calls.where((c) => c.startsWith('create')), isNotEmpty);
  });

  test('an unparseable url blocks submit and marks the field', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('S')
      ..updateCategory('other')
      ..updateUrl('not a url');

    await notifier.submit();

    expect(t.container.read(createStoreStateProvider).urlIsInvalid, isTrue);
    expect(t.stores.calls.where((c) => c.startsWith('create')), isEmpty);
  });

  test('a bare domain is accepted and normalised on the way out', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('S')
      ..updateCategory('other')
      ..updateUrl('shopee.vn/linh');

    await notifier.submit();

    expect(t.container.read(createStoreStateProvider).urlIsInvalid, isFalse);
    expect(t.stores.calls.where((c) => c.startsWith('create')), isNotEmpty);
  });

  test('an empty url is not an invalid one', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('S')
      ..updateCategory('other')
      ..updateUrl('   ');

    await notifier.submit();

    expect(t.container.read(createStoreStateProvider).urlIsInvalid, isFalse);
    expect(t.stores.calls.where((c) => c.startsWith('create')), isNotEmpty);
  });

  test('a failed category load is recoverable', () async {
    final stores = FakeStoreRepository(
      categoryList: _categories,
      error: const NetworkException(),
    );
    final t = build(stores: stores);
    final notifier = t.container.read(createStoreStateProvider.notifier);

    await notifier.loadCategories();
    expect(t.container.read(createStoreStateProvider).isError, isTrue);

    stores.error = null;
    await notifier.loadCategories();
    expect(t.container.read(createStoreStateProvider).categories, isNotEmpty);
  });

  test('a picked logo is uploaded and carried into the create call', () async {
    final t = build();
    final notifier = t.container.read(createStoreStateProvider.notifier)
      ..updateName('S')
      ..updateCategory('other');

    await notifier.pickedLogo(bytes: Uint8List(3), fileExtension: 'png');

    expect(t.media.calls, contains('uploadStoreLogo'));
    expect(t.container.read(createStoreStateProvider).logoUrl, isNotNull);
  });
}
