import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/create_store/pages/create_store_page.dart';
import 'package:mine_storage/features/onboarding/profile/pages/profile_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const _categories = [
  StoreCategory(
    code: 'grocery', nameVi: 'Tạp hóa', nameEn: 'Grocery & convenience',
    icon: 'basket', sortOrder: 10,
  ),
];

Widget host(Widget child, {required ThemeMode mode}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: const UserEntity(id: 'uid-1', email: 'maya@northsidegrocers.com'),
        ),
      ),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(categoryList: _categories),
      ),
      mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: child,
    ),
  );
}

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void sizeToPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  for (final (name, mode) in [('light', ThemeMode.light), ('dark', ThemeMode.dark)]) {
    testWidgets('onboarding profile golden · $name', (tester) async {
      sizeToPhone(tester);
      await tester.pumpWidget(host(const ProfilePage(), mode: mode));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ProfilePage),
        matchesGoldenFile('../../goldens/onboarding_profile_$name.png'),
      );
    });

    testWidgets('onboarding create shop golden · $name', (tester) async {
      sizeToPhone(tester);
      await tester.pumpWidget(host(const CreateStorePage(), mode: mode));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CreateStorePage),
        matchesGoldenFile('../../goldens/onboarding_create_store_$name.png'),
      );
    });
  }
}
