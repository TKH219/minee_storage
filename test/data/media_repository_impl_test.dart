import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/media_repository_impl.dart';

import '../support/fake_storage_data_source.dart';
import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('a user avatar lands under users/<uid>/', () async {
    final source = FakeStorageDataSource();
    final repository = MediaRepositoryImpl(source);

    final url = await repository.uploadUserAvatar(
      bytes: Uint8List(3),
      fileExtension: 'jpg',
    );

    expect(source.lastPath, startsWith('users/uid-1/'));
    expect(source.lastPath, endsWith('.jpg'));
    expect(source.lastContentType, 'image/jpeg');
    expect(url, source.returnedUrl);
  });

  test('a store logo lands under stores/<uid>/', () async {
    final source = FakeStorageDataSource();

    await MediaRepositoryImpl(source).uploadStoreLogo(
      bytes: Uint8List(3),
      fileExtension: 'png',
    );

    expect(source.lastPath, startsWith('stores/uid-1/'));
    expect(source.lastContentType, 'image/png');
  });

  test('the uid is the second path segment, which is what storage RLS checks', () async {
    final source = FakeStorageDataSource(currentId: 'abc-123');

    await MediaRepositoryImpl(source).uploadUserAvatar(
      bytes: Uint8List(3),
      fileExtension: 'jpg',
    );

    expect(source.lastPath!.split('/')[1], 'abc-123');
  });

  test('an unsupported extension is refused before any upload', () async {
    final source = FakeStorageDataSource();
    final repository = MediaRepositoryImpl(source);

    await expectLater(
      () => repository.uploadUserAvatar(bytes: Uint8List(3), fileExtension: 'svg'),
      throwsA(isA<BadRequestException>()),
    );
    expect(source.calls, isEmpty);
  });

  test('uploading without a session is refused', () async {
    final repository = MediaRepositoryImpl(FakeStorageDataSource(currentId: null));

    expect(
      () => repository.uploadUserAvatar(bytes: Uint8List(3), fileExtension: 'jpg'),
      throwsA(isA<UnauthorizedException>()),
    );
  });
}
