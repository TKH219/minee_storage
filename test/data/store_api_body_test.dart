import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/data_sources/remote/store_api.dart';
import 'package:mine_storage/data/models/models.dart';

import '../support/localization_test_harness.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
        '[{"id":"s-new","owner_id":"uid-1","name":"T","currency_id":"c",'
        '"timezone":"Asia/Ho_Chi_Minh","created_at":"2026-08-01T09:00:00.000Z",'
        '"updated_at":"2026-08-02T09:00:00.000Z"}]', 201, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(useLocale);

  test('the request model becomes the JSON body PostgREST receives', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://project.supabase.co'));
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;

    await StoreApi(dio).insertStore(
      const CreateStoreRequest(
        ownerId: 'uid-1',
        name: 'Tạp hóa Linh',
        categoryCode: 'grocery',
        currencyId: 'cur-vnd',
        url: 'https://shopee.vn/linh',
      ),
    );

    final sent = adapter.captured!;
    expect(sent.method, 'POST');
    expect(sent.path, '/rest/v1/stores');
    expect(sent.headers['Prefer'], 'return=representation');
    expect(jsonDecode(jsonEncode(sent.data)), {
      'owner_id': 'uid-1',
      'name': 'Tạp hóa Linh',
      'category_code': 'grocery',
      'currency_id': 'cur-vnd',
      'url': 'https://shopee.vn/linh',
    });
  });
}
