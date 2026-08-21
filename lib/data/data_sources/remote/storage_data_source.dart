import 'dart:typed_data';

abstract class StorageDataSource {
  /// Uploads and returns the public URL of the stored object.
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  String? get currentUserId;
}
