import 'package:equatable/equatable.dart';

enum ProductQuickFilter { all, expiringSoon, expired, archived }

class ProductFilter extends Equatable {
  const ProductFilter({
    this.query = '',
    this.category,
    this.createdFrom,
    this.createdTo,
    this.expiryFrom,
    this.expiryTo,
    this.quickFilter = ProductQuickFilter.all,
  });

  final String query;
  final String? category;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final DateTime? expiryFrom;
  final DateTime? expiryTo;
  final ProductQuickFilter quickFilter;

  /// The query is excluded because its field is already visible on screen.
  bool get hasActiveFilters =>
      category != null ||
      createdFrom != null ||
      createdTo != null ||
      expiryFrom != null ||
      expiryTo != null;

  Map<String, dynamic> toQueryParameters() {
    final trimmed = query.trim();
    return <String, dynamic>{
      if (trimmed.isNotEmpty) 'search': trimmed,
      if (category != null) 'category': category,
      if (createdFrom != null) 'createdFrom': createdFrom!.toUtc().toIso8601String(),
      if (createdTo != null) 'createdTo': createdTo!.toUtc().toIso8601String(),
      if (expiryFrom != null) 'expiryFrom': expiryFrom!.toUtc().toIso8601String(),
      if (expiryTo != null) 'expiryTo': expiryTo!.toUtc().toIso8601String(),
      'status': quickFilter.name,
    };
  }

  /// The `clear*` flags exist because a plain `??` merge can never null a field
  /// back out, and every filter here is clearable from the UI.
  ProductFilter copyWith({
    String? query,
    String? category,
    DateTime? createdFrom,
    DateTime? createdTo,
    DateTime? expiryFrom,
    DateTime? expiryTo,
    ProductQuickFilter? quickFilter,
    bool clearCategory = false,
    bool clearCreatedRange = false,
    bool clearExpiryRange = false,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      createdFrom: clearCreatedRange ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearCreatedRange ? null : (createdTo ?? this.createdTo),
      expiryFrom: clearExpiryRange ? null : (expiryFrom ?? this.expiryFrom),
      expiryTo: clearExpiryRange ? null : (expiryTo ?? this.expiryTo),
      quickFilter: quickFilter ?? this.quickFilter,
    );
  }

  @override
  List<Object?> get props => [
    query,
    category,
    createdFrom,
    createdTo,
    expiryFrom,
    expiryTo,
    quickFilter,
  ];
}
