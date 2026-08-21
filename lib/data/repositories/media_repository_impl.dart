import 'dart:typed_data';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/exceptions/supabase_error_mapper.dart';
import 'package:mine_storage/data/data_sources/remote/storage_data_source.dart';
import 'package:mine_storage/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._dataSource);

  static const Map<String, String> _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  final StorageDataSource _dataSource;

  @override
  Future<String> uploadUserAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) => _upload('users', bytes, fileExtension);

  @override
  Future<String> uploadStoreLogo({
    required Uint8List bytes,
    required String fileExtension,
  }) => _upload('stores', bytes, fileExtension);

  /// The uid is the *second* path segment because that is the segment the
  /// storage policy compares against `auth.uid()`.
  Future<String> _upload(String prefix, Uint8List bytes, String fileExtension) {
    final extension = fileExtension.toLowerCase().replaceFirst('.', '');
    final contentType = _contentTypes[extension];
    if (contentType == null) {
      throw const BadRequestException(message: 'That image format is not supported.');
    }

    final ownerId = _dataSource.currentUserId;
    if (ownerId == null) {
      throw const UnauthorizedException(
        message: 'Your session has expired. Please sign in again.',
      );
    }

    return _guard(() {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      return _dataSource.upload(
        path: '$prefix/$ownerId/$stamp.$extension',
        bytes: bytes,
        contentType: contentType,
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (e) {
      throw SupabaseErrorMapper.map(e);
    }
  }
}
