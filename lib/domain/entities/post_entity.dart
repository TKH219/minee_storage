import 'package:equatable/equatable.dart';

/// Demo entity for the reference vertical slice.
///
/// Delete this file along with `PostModel`, `PostApi`, `PostRepository` and the
/// `home` feature once the real Mine Storage API lands.
class PostEntity extends Equatable {
  const PostEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, userId, title, body];
}
