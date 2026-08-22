import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/data_sources/remote/storage_data_source_impl.dart';

import '../support/localization_test_harness.dart';

/// Captures the request instead of sending it.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;
  List<int> body = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    return ResponseBody.fromString('{"Key":"avatars/users/uid-1/1.jpg"}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(useLocale);

  ({StorageDataSourceImpl source, _RecordingAdapter adapter}) build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://project.supabase.co'));
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    return (
      source: StorageDataSourceImpl(dio, currentUserId: () => 'uid-1'),
      adapter: adapter,
    );
  }

  test('uploads to the storage object endpoint for the bucket', () async {
    final t = build();

    await t.source.upload(
      path: 'users/uid-1/1.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );

    expect(t.adapter.captured!.method, 'POST');
    expect(t.adapter.captured!.path, '/storage/v1/object/avatars/users/uid-1/1.jpg');
    expect(t.adapter.captured!.headers['Content-Type'], 'image/jpeg');
    expect(t.adapter.body, [1, 2, 3]);
  });

  test('an existing object is replaced rather than rejected', () async {
    final t = build();

    await t.source.upload(
      path: 'users/uid-1/1.jpg',
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    );

    expect(t.adapter.captured!.headers['x-upsert'], 'true');
  });

  test('returns the public url, which is what the app stores', () async {
    final t = build();

    final url = await t.source.upload(
      path: 'users/uid-1/1.jpg',
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    );

    expect(
      url,
      'https://project.supabase.co/storage/v1/object/public/avatars/users/uid-1/1.jpg',
    );
  });

  test('the current user id comes from the injected session getter', () {
    expect(build().source.currentUserId, 'uid-1');
  });

  test('a base url with a trailing slash does not yield a doubled one', () async {
    // API_URL is configured with a trailing slash, and this URL is persisted
    // as logo_url / avatar_url — a malformed one would be stored for good.
    final dio = Dio(BaseOptions(baseUrl: 'https://project.supabase.co/'));
    dio.httpClientAdapter = _RecordingAdapter();
    final source = StorageDataSourceImpl(dio, currentUserId: () => 'uid-1');

    final url = await source.upload(
      path: 'users/uid-1/1.jpg',
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    );

    expect(url, isNot(contains('.co//')));
    expect(
      url,
      'https://project.supabase.co/storage/v1/object/public/avatars/users/uid-1/1.jpg',
    );
  });
}
