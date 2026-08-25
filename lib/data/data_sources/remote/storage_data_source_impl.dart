import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:mine_storage/data/data_sources/remote/storage_data_source.dart';

class StorageDataSourceImpl implements StorageDataSource {
  StorageDataSourceImpl(
    this._dio, {
    required String? Function() currentUserId,
    this.bucket = 'avatars',
  }) : _currentUserId = currentUserId;

  final Dio _dio;
  final String? Function() _currentUserId;
  final String bucket;

  @override
  String? get currentUserId => _currentUserId();

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    String? bucket,
  }) async {
    final target = bucket ?? this.bucket;

    await _dio.post<dynamic>(
      '/storage/v1/object/$target/$path',
      data: Stream<List<int>>.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          Headers.contentLengthHeader: bytes.length,
          // Re-picking a photo overwrites the previous object rather than
          // failing with "resource already exists".
          'x-upsert': 'true',
        },
      ),
    );

    // API_URL is configured with a trailing slash, and this URL is stored on
    // the row — a doubled slash would be persisted, not just requested.
    final base = _dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/storage/v1/object/public/$target/$path';
  }
}
