import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';

Map<String, dynamic> batchJson({String remaining = '2.500'}) => {
  'id': 'b1',
  'productId': 'p1',
  'storeId': 'store-a',
  'batchCode': '#B-0001',
  'purchasedAt': '2026-08-01T00:00:00.000Z',
  'unitPrice': '12.75',
  'expiryDate': '2026-09-01',
  'initialQuantity': '5.000',
  'remainingQuantity': remaining,
  'supplier': 'Basso Srl',
  'storageLocation': 'Shelf A',
  'note': null,
  'createdAt': '2026-08-01T00:00:00.000Z',
  'updatedAt': '2026-08-02T00:00:00.000Z',
  'deletedAt': null,
};

Map<String, dynamic> productJson() => {
  'id': 'p1',
  'name': 'Olive oil',
  'unit': 'litre',
  'barcode': '8934567890123',
  'brand': 'Basso',
  'category': 'Pantry',
  'notes': 'Cold pressed',
  'photoUrl': 'https://cdn.example.com/p1.jpg',
  'createdAt': '2026-07-01T00:00:00.000Z',
  'updatedAt': '2026-07-02T00:00:00.000Z',
  'deletedAt': null,
  'batches': [batchJson()],
};

void main() {
  test('parses decimal strings without loss', () {
    final entity = ProductBatchModel.fromJson(batchJson()).toEntity();

    expect(entity.unitPrice, Decimal.parse('12.75'));
    expect(entity.remainingQuantity, Decimal.parse('2.500'));
    expect(entity.initialQuantity, Decimal.parse('5.000'));
  });

  test('parses timestamps', () {
    final entity = ProductBatchModel.fromJson(batchJson()).toEntity();

    expect(entity.purchasedAt, DateTime.parse('2026-08-01T00:00:00.000Z'));
    expect(entity.expiryDate, DateTime.parse('2026-09-01'));
  });

  test('maps every product field and nests its batches', () {
    final entity = ProductModel.fromJson(productJson()).toEntity();

    expect(entity.id, 'p1');
    expect(entity.name, 'Olive oil');
    expect(entity.barcode, '8934567890123');
    expect(entity.brand, 'Basso');
    expect(entity.category, 'Pantry');
    expect(entity.unit, ProductUnit.litre);
    expect(entity.notes, 'Cold pressed');
    expect(entity.photoUrl, 'https://cdn.example.com/p1.jpg');
    expect(entity.archived, isFalse);
    expect(entity.batches, hasLength(1));
    expect(entity.batches.single.id, 'b1');
    // Where the goods sit belongs to the delivery, not to the catalogue entry.
    expect(entity.batches.single.storageLocation, 'Shelf A');
    expect(entity.batches.single.storeId, 'store-a');
    expect(entity.batches.single.batchCode, '#B-0001');
  });

  test('tolerates absent optional fields and an absent batch list', () {
    final entity = ProductModel.fromJson({
      'id': 'p2',
      'name': 'Rice',
      'createdAt': '2026-07-01T00:00:00.000Z',
      'updatedAt': '2026-07-01T00:00:00.000Z',
    }).toEntity();

    expect(entity.barcode, isNull);
    expect(entity.photoUrl, isNull);
    expect(entity.batches, isEmpty);
  });

  test('maps a page, preserving order', () {
    final paged = PagedProductsModel.fromJson({
      'items': [
        productJson(),
        {...productJson(), 'id': 'p2', 'name': 'Rice'},
      ],
      'hasMore': true,
    }).toEntity();

    expect(paged.hasMore, isTrue);
    expect(paged.items.map((p) => p.id), ['p1', 'p2']);
  });

  test('a deletion stamp on the wire becomes an archived entity', () {
    final json = productJson()..['deletedAt'] = '2026-08-20T00:00:00.000Z';

    expect(ProductModel.fromJson(json).toEntity().archived, isTrue);
  });

  test('an undated batch survives a null expiry', () {
    final json = batchJson()..['expiryDate'] = null;

    expect(ProductBatchModel.fromJson(json).toEntity().expiryDate, isNull);
  });

  test('an absent unit falls back to piece rather than throwing', () {
    final json = productJson()..remove('unit');

    expect(ProductModel.fromJson(json).toEntity().unit, ProductUnit.piece);
  });
}
