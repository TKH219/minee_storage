import 'dart:typed_data';

abstract class MediaRepository {
  /// Returns the public URL of the uploaded image.
  Future<String> uploadUserAvatar({
    required Uint8List bytes,
    required String fileExtension,
  });

  Future<String> uploadStoreLogo({
    required Uint8List bytes,
    required String fileExtension,
  });

  /// Product images live in their own bucket, so a shop's logo and its stock
  /// photos can be governed separately.
  Future<String> uploadProductPhoto({
    required Uint8List bytes,
    required String fileExtension,
  });
}
