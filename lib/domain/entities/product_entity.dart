import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/expiry_status.dart';
import 'package:mine_storage/domain/entities/product_batch_entity.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.brand,
    this.category,
    this.storageLocation,
    this.notes,
    this.photoUrl,
    this.isArchived = false,
    this.batches = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? storageLocation;
  final String? notes;
  final String? photoUrl;
  final bool isArchived;
  final List<ProductBatchEntity> batches;

  Decimal get totalRemaining => batches
      .where((batch) => !batch.isArchived)
      .fold(Decimal.zero, (sum, batch) => sum + batch.remainingQuantity);

  bool get hasStock => totalRemaining > Decimal.zero;

  /// Live batches in the order stock is drawn from them.
  List<ProductBatchEntity> get availableBatches {
    return batches.where((batch) => !batch.isArchived && batch.hasStock).toList()
      ..sort(compareBatchesFefo);
  }

  /// Only batches that still hold quantity can set the nearest expiry, so an
  /// emptied expired batch never makes the product read as expired.
  DateTime? get nearestExpiry {
    for (final batch in availableBatches) {
      if (batch.expiryDate != null) return batch.expiryDate;
    }
    return null;
  }

  /// Spans depleted batches too — price history outlives stock.
  Decimal? get latestUnitPrice {
    final live = batches.where((batch) => !batch.isArchived).toList();
    if (live.isEmpty) return null;
    live.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return live.first.unitPrice;
  }

  ExpiryStatus statusOn(DateTime today) =>
      expiryStatusFor(nearestExpiry: nearestExpiry, hasStock: hasStock, today: today);

  ProductEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? barcode,
    String? brand,
    String? category,
    String? storageLocation,
    String? notes,
    String? photoUrl,
    bool? isArchived,
    List<ProductBatchEntity>? batches,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      storageLocation: storageLocation ?? this.storageLocation,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      isArchived: isArchived ?? this.isArchived,
      batches: batches ?? this.batches,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    updatedAt,
    barcode,
    brand,
    category,
    storageLocation,
    notes,
    photoUrl,
    isArchived,
    batches,
  ];
}
