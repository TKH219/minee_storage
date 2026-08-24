import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// One purchase lot. Buying price and expiry belong here, not on the product —
/// both change with every purchase.
class ProductBatchEntity extends Equatable {
  const ProductBatchEntity({
    required this.id,
    required this.productId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.createdAt,
    this.expiryDate,
    this.isArchived = false,
  });

  final String id;
  final String productId;
  final DateTime purchasedAt;
  final Decimal unitPrice;

  /// Null for goods the shop does not date — hardware, packaging. Undated
  /// batches still hold stock, they just never expire.
  final DateTime? expiryDate;
  final Decimal initialQuantity;
  final Decimal remainingQuantity;
  final DateTime createdAt;
  final bool isArchived;

  Decimal get totalCost => unitPrice * initialQuantity;

  bool get hasStock => remainingQuantity > Decimal.zero;

  bool isExpiredAt(DateTime now) => expiryDate != null && !expiryDate!.isAfter(now);

  ProductBatchEntity copyWith({
    String? id,
    String? productId,
    DateTime? purchasedAt,
    Decimal? unitPrice,
    DateTime? expiryDate,
    Decimal? initialQuantity,
    Decimal? remainingQuantity,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return ProductBatchEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      unitPrice: unitPrice ?? this.unitPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    purchasedAt,
    unitPrice,
    expiryDate,
    initialQuantity,
    remainingQuantity,
    createdAt,
    isArchived,
  ];
}

/// Dated batches drain before undated ones; ties and undated batches fall back
/// to purchase order. Shared by [ProductEntity.availableBatches] and the
/// allocator so a preview and the allocation it previews cannot disagree.
int compareBatchesFefo(ProductBatchEntity a, ProductBatchEntity b) {
  final aExpiry = a.expiryDate;
  final bExpiry = b.expiryDate;
  if (aExpiry != null && bExpiry != null) {
    final byExpiry = aExpiry.compareTo(bExpiry);
    if (byExpiry != 0) return byExpiry;
  } else if (aExpiry != null) {
    return -1;
  } else if (bExpiry != null) {
    return 1;
  }
  return a.purchasedAt.compareTo(b.purchasedAt);
}
