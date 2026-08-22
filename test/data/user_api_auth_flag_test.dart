import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/network/interceptors/supabase_rest_interceptor.dart';
import 'package:mine_storage/data/data_sources/remote/user_api.dart';

import '../support/localization_test_harness.dart';

/// Answers every request, recording the headers the pipeline actually produced.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('"none"', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(useLocale);

  ({UserApi api, _RecordingAdapter adapter}) build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://project.supabase.co'));
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      SupabaseRestInterceptor(anonKey: 'anon-123', accessToken: () => 'jwt-abc'),
    );
    return (api: UserApi(dio), adapter: adapter);
  }

  test('the email-status check goes out without the session token', () async {
    final t = build();

    await t.api.emailStatus({'p_email': 'a@b.com'});

    final sent = t.adapter.requests.single;
    expect(sent.extra[SupabaseRestInterceptor.requiresAuthKey], isFalse);
    expect(sent.headers['Authorization'], 'Bearer anon-123');
    expect(sent.headers['apikey'], 'anon-123');
  });

  test('a profile read still carries the session token', () async {
    final t = build();

    await t.api.fetchUser(id: 'eq.uid-1');

    expect(t.adapter.requests.single.headers['Authorization'], 'Bearer jwt-abc');
  });
}
