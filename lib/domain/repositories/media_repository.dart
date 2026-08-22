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
}
