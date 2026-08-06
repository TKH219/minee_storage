import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'post_model.g.dart';

/// Demo model for the reference vertical slice. Mirrors the wire format
/// exactly; [toEntity] is the only place the domain learns about it.
@JsonSerializable(createToJson: false)
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);

  final int id;
  final int userId;
  final String title;
  final String body;

  PostEntity toEntity() => PostEntity(
    id: id,
    userId: userId,
    title: title,
    body: body,
  );
}
