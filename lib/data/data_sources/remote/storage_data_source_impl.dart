import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/data/data_sources/remote/storage_data_source.dart';

class StorageDataSourceImpl implements StorageDataSource {
  StorageDataSourceImpl(this._client, {this.bucket = 'avatars'});

  final SupabaseClient _client;
  final String bucket;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
