import 'dart:typed_data';

import 'package:mine_storage/domain/repositories/media_repository.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({this.returnedUrl = 'https://cdn.example/x.jpg', this.error});

  String returnedUrl;
  Object? error;

  final List<String> calls = [];

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  Future<String> uploadUserAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    calls.add('uploadUserAvatar');
    _maybeThrow();
    return returnedUrl;
  }

  @override
  Future<String> uploadStoreLogo({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    calls.add('uploadStoreLogo');
    _maybeThrow();
    return returnedUrl;
  }

  @override
  Future<String> uploadProductPhoto({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    calls.add('uploadProductPhoto');
    _maybeThrow();
    return returnedUrl;
  }
}
