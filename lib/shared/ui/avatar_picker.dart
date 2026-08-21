import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

enum AvatarPickerShape { circle, rounded }

/// A tappable image well with an initials fallback.
///
/// Deliberately presentational: it reports a tap and renders whatever state it
/// is given, so picking and uploading stay in the notifier and this stays
/// testable without platform channels.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.initials,
    this.imageUrl,
    this.isUploading = false,
    this.shape = AvatarPickerShape.circle,
    this.onPick,
  });

  static const double _circleSize = 88;
  static const double _roundedSize = 64;

  final String initials;
  final String? imageUrl;
  final bool isUploading;
  final AvatarPickerShape shape;
  final VoidCallback? onPick;

  bool get _isCircle => shape == AvatarPickerShape.circle;

  double get _size => _isCircle ? _circleSize : _roundedSize;

  BorderRadius get _radius =>
      BorderRadius.circular(_isCircle ? _circleSize / 2 : 12);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: isUploading ? null : onPick,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: isUploading ? colors.neutral2 : colors.neutral1,
              borderRadius: _radius,
              border: Border.all(
                color: colors.neutral3,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              image: imageUrl == null
                  ? null
                  : DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover),
            ),
            child: _buildContent(context),
          ),
          if (!isUploading && imageUrl == null) _buildCameraBadge(context),
        ],
      ),
    );
  }

  Widget? _buildContent(BuildContext context) {
    if (isUploading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.colors.inkPrimary,
          ),
        ),
      );
    }
    if (imageUrl != null) return null;

    return Center(
      child: Text(
        initials,
        style: context.textStyles.sansTitleHeading2.copyWith(
          color: context.colors.neutral6,
          fontSize: _isCircle ? 26 : 20,
        ),
      ),
    );
  }

  Widget _buildCameraBadge(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      right: -2,
      bottom: -2,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors.neutral0,
          shape: BoxShape.circle,
          border: Border.all(color: colors.neutral2),
        ),
        child: Icon(Icons.photo_camera_outlined, size: 17, color: colors.neutral7),
      ),
    );
  }
}
