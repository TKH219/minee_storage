import 'dart:typed_data';

abstract class StorageDataSource {
  /// Uploads and returns the public URL of the stored object.
  ///
  /// [bucket] overrides the instance default — avatars, store logos and product
  /// images live in separate buckets with separate policies.
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    String? bucket,
  });

  String? get currentUserId;
}
