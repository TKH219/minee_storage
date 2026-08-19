import 'package:equatable/equatable.dart';

import 'expiry_status.dart';
import 'lot.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.barcode,
    this.brand,
    this.category,
    this.location,
    this.notes,
    this.archived = false,
    this.lots = const [],
  });

  final String id;
  final String storeId;
  final String name;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? location;
  final String? notes;
  final bool archived;
  final List<Lot> lots;

  List<Lot> get _stocked => lots.where((l) => l.hasStock).toList();

  double get totalRemaining => _stocked.fold(0, (sum, l) => sum + l.remainingQuantity);

  bool get hasStock => totalRemaining > 0;

  /// Only lots that still hold quantity can set the nearest expiry, so an
  /// emptied expired lot never makes the product read as expired.
  DateTime? get nearestExpiry {
    final dates = _stocked.map((l) => l.expiresOn).whereType<DateTime>().toList()..sort();
    return dates.isEmpty ? null : dates.first;
  }

  double? get latestUnitPrice {
    if (lots.isEmpty) return null;
    final sorted = [...lots]..sort((a, b) => a.purchasedOn.compareTo(b.purchasedOn));
    return sorted.last.unitPrice;
  }

  /// Dated lots drain before undated ones; undated lots fall back to purchase order.
  List<Lot> get lotsFefo {
    final dated = lots.where((l) => l.expiresOn != null).toList()
      ..sort((a, b) => a.expiresOn!.compareTo(b.expiresOn!));
    final undated = lots.where((l) => l.expiresOn == null).toList()
      ..sort((a, b) => a.purchasedOn.compareTo(b.purchasedOn));
    return [...dated, ...undated];
  }

  ExpiryStatus statusOn(DateTime today) =>
      expiryStatusFor(nearestExpiry: nearestExpiry, hasStock: hasStock, today: today);

  Product copyWith({bool? archived, List<Lot>? lots}) => Product(
        id: id,
        storeId: storeId,
        name: name,
        barcode: barcode,
        brand: brand,
        category: category,
        location: location,
        notes: notes,
        archived: archived ?? this.archived,
        lots: lots ?? this.lots,
      );

  @override
  List<Object?> get props =>
      [id, storeId, name, barcode, brand, category, location, notes, archived, lots];
}
