import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/product_unit.dart';

/// What a form hands the repository. Keeps request models out of features.
class ProductDraft extends Equatable {
  const ProductDraft({
    required this.name,
    this.unit = ProductUnit.piece,
    this.barcode,
    this.brand,
    this.category,
    this.notes,
    this.photoUrl,
  });

  final String name;
  final ProductUnit unit;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? notes;
  final String? photoUrl;

  @override
  List<Object?> get props => [name, unit, barcode, brand, category, notes, photoUrl];
}

class BatchDraft extends Equatable {
  const BatchDraft({
    required this.storeId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
  });

  /// Which shop the delivery landed at. The product is user-wide, so this is
  /// the only thing that files the stock anywhere.
  final String storeId;
  final DateTime purchasedAt;
  final Decimal unitPrice;

  /// Null for goods the shop does not date.
  final DateTime? expiryDate;
  /// What the delivery brought in. Never a statement about what is left: the
  /// remainder moves only through a stock transaction.
  final Decimal initialQuantity;
  final String? supplier;
  final String? storageLocation;
  final String? note;

  @override
  List<Object?> get props => [
    storeId,
    purchasedAt,
    unitPrice,
    expiryDate,
    initialQuantity,
    supplier,
    storageLocation,
    note,
  ];
}
