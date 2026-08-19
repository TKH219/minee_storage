import 'package:equatable/equatable.dart';

class Lot extends Equatable {
  const Lot({
    required this.id,
    required this.productId,
    required this.purchasedOn,
    this.expiresOn,
    required this.unitPrice,
    required this.initialQuantity,
    required this.remainingQuantity,
  });

  final String id;
  final String productId;
  final DateTime purchasedOn;
  final DateTime? expiresOn;
  final double unitPrice;
  final double initialQuantity;
  final double remainingQuantity;

  double get lotTotal => unitPrice * initialQuantity;

  bool get hasStock => remainingQuantity > 0;

  bool get isDepleted => !hasStock;

  Lot copyWith({double? remainingQuantity}) => Lot(
        id: id,
        productId: productId,
        purchasedOn: purchasedOn,
        expiresOn: expiresOn,
        unitPrice: unitPrice,
        initialQuantity: initialQuantity,
        remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      );

  @override
  List<Object?> get props =>
      [id, productId, purchasedOn, expiresOn, unitPrice, initialQuantity, remainingQuantity];
}
