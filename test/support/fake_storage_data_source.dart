import 'dart:typed_data';

import 'package:mine_storage/data/data_sources/remote/storage_data_source.dart';

class FakeStorageDataSource implements StorageDataSource {
  FakeStorageDataSource({
    this.currentId = 'uid-1',
    this.returnedUrl = 'https://cdn.example/avatars/x.jpg',
    this.error,
  });

  String? currentId;
  String returnedUrl;
  Object? error;

  final List<String> calls = [];
  String? lastPath;
  String? lastContentType;

  @override
  String? get currentUserId => currentId;

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    calls.add('upload:$path');
    if (error != null) throw error!;
    lastPath = path;
    lastContentType = contentType;
    return returnedUrl;
  }
}
