import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// What a form hands the repository. Keeps request models out of features.
class ProductDraft extends Equatable {
  const ProductDraft({
    required this.name,
    this.barcode,
    this.brand,
    this.category,
    this.storageLocation,
    this.notes,
    this.photoUrl,
  });

  final String name;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? storageLocation;
  final String? notes;
  final String? photoUrl;

  @override
  List<Object?> get props => [
    name,
    barcode,
    brand,
    category,
    storageLocation,
    notes,
    photoUrl,
  ];
}

class BatchDraft extends Equatable {
  const BatchDraft({
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    this.expiryDate,
    this.remainingQuantity,
  });

  final DateTime purchasedAt;
  final Decimal unitPrice;

  /// Null for goods the shop does not date.
  final DateTime? expiryDate;
  final Decimal initialQuantity;

  /// Null on create — the server seeds it from [initialQuantity].
  final Decimal? remainingQuantity;

  @override
  List<Object?> get props => [
    purchasedAt,
    unitPrice,
    expiryDate,
    initialQuantity,
    remainingQuantity,
  ];
}
