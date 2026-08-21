import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/profile/pages/profile_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/avatar_picker.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

Widget host({Brightness brightness = Brightness.light}) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: const UserEntity(id: 'uid-1', email: 'a@b.com')),
        ),
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        mediaRepositoryProvider.overrideWithValue(FakeMediaRepository()),
        routerProvider.overrideWithValue(buildTestRouter()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
        home: const ProfilePage(),
      ),
    );

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('carries the design copy', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('Tell us who you are'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Continue is held until a name is entered', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Maya Chen');
    await tester.pump();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('there is exactly one field and one avatar well', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byType(AvatarPicker), findsOneWidget);
  });

  testWidgets('the screen cannot be popped', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(tester.widget<PopScope>(find.byType(PopScope).first).canPop, isFalse);
  });

  testWidgets('renders in dark without throwing', (tester) async {
    await tester.pumpWidget(host(brightness: Brightness.dark));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
