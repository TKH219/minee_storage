import 'package:flutter/material.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';

class PostItem extends StatelessWidget {
  const PostItem({super.key, required this.post, this.onTap});

  final PostEntity post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: context.colors.primary1,
                    child: Text(
                      '${post.userId}',
                      style: context.textStyles.sansCaption.copyWith(
                        color: context.colors.primary5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.title.capitalizeFirst(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.sansBodyBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.body.capitalizeFirst(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
