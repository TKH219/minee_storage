import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// One delivery into one store. Cost, expiry and quantity belong here, not on
/// the product — all three change with every purchase, and the same goods
/// bought twice at different prices must stay two lots rather than an average.
class ProductBatchEntity extends Equatable {
  const ProductBatchEntity({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.batchCode,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String productId;
  final String storeId;

  /// `#B-0001`, sequential per product across every store, so one store's list
  /// may show gaps with the missing codes sitting in the owner's other shops.
  final String batchCode;
  final DateTime purchasedAt;
  final Decimal unitPrice;

  /// Null for goods the shop does not date — hardware, packaging. Undated
  /// batches still hold stock, they just never expire.
  final DateTime? expiryDate;
  final Decimal initialQuantity;
  final Decimal remainingQuantity;
  final String? supplier;

  /// Where this delivery physically sits. A property of the delivery, not of
  /// the product: the same goods stocked in three shops sit in three places.
  final String? storageLocation;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get archived => deletedAt != null;

  Decimal get totalCost => unitPrice * initialQuantity;

  bool get hasStock => remainingQuantity > Decimal.zero;

  bool isExpiredAt(DateTime now) => expiryDate != null && !expiryDate!.isAfter(now);

  ProductBatchEntity copyWith({
    String? id,
    String? productId,
    String? storeId,
    String? batchCode,
    DateTime? purchasedAt,
    Decimal? unitPrice,
    DateTime? expiryDate,
    Decimal? initialQuantity,
    Decimal? remainingQuantity,
    String? supplier,
    String? storageLocation,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool clearExpiryDate = false,
  }) {
    return ProductBatchEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      batchCode: batchCode ?? this.batchCode,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      unitPrice: unitPrice ?? this.unitPrice,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      initialQuantity: initialQuantity ?? this.initialQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      supplier: supplier ?? this.supplier,
      storageLocation: storageLocation ?? this.storageLocation,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    storeId,
    batchCode,
    purchasedAt,
    unitPrice,
    expiryDate,
    initialQuantity,
    remainingQuantity,
    supplier,
    storageLocation,
    note,
    createdAt,
    updatedAt,
    deletedAt,
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
