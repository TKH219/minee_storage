import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/product_entity.dart';

class PagedProducts extends Equatable {
  const PagedProducts({required this.items, required this.hasMore});

  final List<ProductEntity> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}
