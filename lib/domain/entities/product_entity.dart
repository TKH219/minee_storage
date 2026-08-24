import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/expiry_status.dart';
import 'package:mine_storage/domain/entities/product_batch_entity.dart';
import 'package:mine_storage/domain/entities/product_unit.dart';

/// Identity only — no price, no expiry, no quantity. A product belongs to a
/// user rather than a shop, so one catalogue entry serves every store the owner
/// runs and a rename lands in all of them at once.
///
/// [batches] holds only the batches in the store being viewed, so every derived
/// figure below is already scoped to that store.
class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.unit = ProductUnit.piece,
    this.barcode,
    this.brand,
    this.category,
    this.notes,
    this.photoUrl,
    this.deletedAt,
    this.batches = const [],
  });

  final String id;
  final String name;
  final ProductUnit unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? notes;
  final String? photoUrl;
  final DateTime? deletedAt;
  final List<ProductBatchEntity> batches;

  bool get archived => deletedAt != null;

  List<ProductBatchEntity> get _live =>
      batches.where((batch) => !batch.archived).toList();

  Decimal get totalRemaining =>
      _live.fold(Decimal.zero, (sum, batch) => sum + batch.remainingQuantity);

  bool get hasStock => totalRemaining > Decimal.zero;

  /// Live batches in the order stock is drawn from them.
  List<ProductBatchEntity> get availableBatches =>
      _live.where((batch) => batch.hasStock).toList()..sort(compareBatchesFefo);

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
    final live = _live;
    if (live.isEmpty) return null;
    live.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return live.first.unitPrice;
  }

  ExpiryStatus statusOn(DateTime today) =>
      expiryStatusFor(nearestExpiry: nearestExpiry, hasStock: hasStock, today: today);

  ProductEntity copyWith({
    String? id,
    String? name,
    ProductUnit? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? barcode,
    String? brand,
    String? category,
    String? notes,
    String? photoUrl,
    DateTime? deletedAt,
    List<ProductBatchEntity>? batches,
    bool clearDeletedAt = false,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      batches: batches ?? this.batches,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    unit,
    createdAt,
    updatedAt,
    barcode,
    brand,
    category,
    notes,
    photoUrl,
    deletedAt,
    batches,
  ];
}
