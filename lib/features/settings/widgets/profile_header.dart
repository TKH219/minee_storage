import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Measured from the design's settings header (`#settings`, node `3321:15803`).
abstract class ProfileHeaderMetrics {
  static const double avatarSize = 76;
  static const double avatarIconSize = 24;
  static const double gap = 8;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(24, 0, 24, 24);
  static const double nameSize = 16;
}

/// Who is signed in. The email is mono so it reads as an identifier rather
/// than prose.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: ProfileHeaderMetrics.padding,
      child: Column(
        children: [
          Container(
            width: ProfileHeaderMetrics.avatarSize,
            height: ProfileHeaderMetrics.avatarSize,
            decoration: BoxDecoration(
              color: colors.neutral2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: ProfileHeaderMetrics.avatarIconSize,
              color: colors.neutral5,
            ),
          ),
          const SizedBox(height: ProfileHeaderMetrics.gap),
          if (name.trim().isNotEmpty)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.sansBodyBold.copyWith(
                fontSize: ProfileHeaderMetrics.nameSize,
              ),
            ),
          const SizedBox(height: ProfileHeaderMetrics.gap),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.monoBody.copyWith(
              fontSize: 12,
              color: colors.neutral6,
            ),
          ),
        ],
      ),
    );
  }
}
