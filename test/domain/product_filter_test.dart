import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  group('toQueryParameters', () {
    test('always sends the quick filter as status', () {
      expect(const ProductFilter().toQueryParameters()['status'], 'all');
      expect(
        const ProductFilter(quickFilter: ProductQuickFilter.expiringSoon)
            .toQueryParameters()['status'],
        'expiringSoon',
      );
    });

    test('omits a blank query', () {
      expect(
        const ProductFilter(query: '   ').toQueryParameters().containsKey('search'),
        isFalse,
      );
    });

    test('trims the query', () {
      expect(const ProductFilter(query: '  oil ').toQueryParameters()['search'], 'oil');
    });

    test('serialises dates as UTC ISO-8601', () {
      final params = ProductFilter(
        createdFrom: DateTime.utc(2026, 8, 1),
        expiryTo: DateTime.utc(2026, 9, 30),
      ).toQueryParameters();

      expect(params['createdFrom'], '2026-08-01T00:00:00.000Z');
      expect(params['expiryTo'], '2026-09-30T00:00:00.000Z');
      expect(params.containsKey('createdTo'), isFalse);
      expect(params.containsKey('expiryFrom'), isFalse);
    });

    test('omits a null category', () {
      expect(const ProductFilter().toQueryParameters().containsKey('category'), isFalse);
    });
  });

  group('hasActiveFilters', () {
    test('is false for a default filter', () {
      expect(const ProductFilter().hasActiveFilters, isFalse);
    });

    test('ignores the query, which has its own visible field', () {
      expect(const ProductFilter(query: 'oil').hasActiveFilters, isFalse);
    });

    test('is true once a date bound is set', () {
      expect(ProductFilter(createdFrom: DateTime.utc(2026)).hasActiveFilters, isTrue);
    });

    test('is true once a category is set', () {
      expect(const ProductFilter(category: 'Pantry').hasActiveFilters, isTrue);
    });
  });

  group('copyWith', () {
    test('replaces a value', () {
      final filter = const ProductFilter().copyWith(category: 'Pantry');

      expect(filter.category, 'Pantry');
    });

    test('clears a nullable value when explicitly asked', () {
      final filter = const ProductFilter(category: 'Pantry').copyWith(clearCategory: true);

      expect(filter.category, isNull);
    });

    test('keeps existing values when a field is omitted', () {
      final filter = const ProductFilter(category: 'Pantry').copyWith(query: 'oil');

      expect(filter.category, 'Pantry');
      expect(filter.query, 'oil');
    });
  });
}
