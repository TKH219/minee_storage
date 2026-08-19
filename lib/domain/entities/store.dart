import 'package:equatable/equatable.dart';

enum StoreRole { owner, manager, staff }

class Store extends Equatable {
  const Store({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.productCount,
    required this.role,
  });

  final String id;
  final String name;
  final String currencyCode;
  final int productCount;
  final StoreRole role;

  @override
  List<Object?> get props => [id, name, currencyCode, productCount, role];
}
