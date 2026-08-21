import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/profile/states/profile_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({
    ProviderContainer container,
    FakeAuthRepository auth,
    FakeMediaRepository media,
    GoRouter router,
  })
  build({FakeMediaRepository? media}) {
    final router = buildTestRouter();
    final auth = FakeAuthRepository(
      user: const UserEntity(id: 'uid-1', email: 'a@b.com'),
    );
    final mediaRepository = media ?? FakeMediaRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        routerProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);
    container.listen(profileStateProvider, (_, _) {});
    return (container: container, auth: auth, media: mediaRepository, router: router);
  }

  test('submit writes the trimmed name and moves to create-shop', () async {
    final t = build();
    final notifier = t.container.read(profileStateProvider.notifier)
      ..updateFullName('  Maya Chen  ');

    await notifier.submit();

    expect(t.auth.calls, contains('updateProfile:Maya Chen'));
    expect(currentPath(t.router), '/onboarding/store');
  });

  test('a blank name never reaches the repository', () async {
    final t = build();

    await t.container.read(profileStateProvider.notifier).submit();

    expect(t.auth.calls.where((c) => c.startsWith('updateProfile')), isEmpty);
    expect(currentPath(t.router), '/');
  });

  test('a whitespace-only name is treated as blank', () async {
    final t = build();
    final notifier = t.container.read(profileStateProvider.notifier)..updateFullName('   ');

    await notifier.submit();

    expect(t.auth.calls.where((c) => c.startsWith('updateProfile')), isEmpty);
  });

  test('canSubmit follows the name', () {
    final t = build();
    final notifier = t.container.read(profileStateProvider.notifier);

    expect(t.container.read(profileStateProvider).canSubmit, isFalse);

    notifier.updateFullName('Maya');

    expect(t.container.read(profileStateProvider).canSubmit, isTrue);
  });

  test('a picked avatar is uploaded and carried into the profile write', () async {
    final t = build();
    final notifier = t.container.read(profileStateProvider.notifier)
      ..updateFullName('Maya Chen');

    await notifier.pickedAvatar(bytes: Uint8List(3), fileExtension: 'jpg');
    await notifier.submit();

    expect(t.media.calls, contains('uploadUserAvatar'));
    expect(t.container.read(profileStateProvider).avatarUrl, 'https://cdn.example/x.jpg');
    expect(t.auth.lastAvatarUrl, 'https://cdn.example/x.jpg');
  });

  test('a failed avatar upload keeps the typed name and surfaces the error', () async {
    final t = build(media: FakeMediaRepository(error: const NetworkException()));
    final notifier = t.container.read(profileStateProvider.notifier)
      ..updateFullName('Maya Chen');

    await notifier.pickedAvatar(bytes: Uint8List(3), fileExtension: 'jpg');

    final state = t.container.read(profileStateProvider);
    expect(state.fullName, 'Maya Chen');
    expect(state.isUploading, isFalse);
    expect(state.avatarUrl, isNull);
    expect(state.isError, isTrue);
  });

  test('initials come from the name, falling back to the email', () {
    final t = build();
    final notifier = t.container.read(profileStateProvider.notifier);

    expect(t.container.read(profileStateProvider).initialsFor('maya@b.com'), 'M');

    notifier.updateFullName('Maya Chen');

    expect(t.container.read(profileStateProvider).initialsFor('maya@b.com'), 'MC');
  });
}
