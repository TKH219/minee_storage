import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/data/mock/mock_database.dart';

void main() {
  late MockDatabase db;

  setUp(() => db = MockDatabase(today: DateTime(2026, 8, 20)));

  test('preview splits FEFO across lots and reports what each leaves behind', () {
    final preview = db.previewConsumption('milk', 6);
    expect(preview, hasLength(2));
    expect(preview.first.quantity, 2);
    expect(preview.first.emptiesLot, isTrue);
    expect(preview.last.quantity, 4);
    expect(preview.last.emptiesLot, isFalse);
    expect(preview.last.remainingAfter, 4);
  });

  test('consumption refuses partial fulfilment outright', () {
    expect(() => db.previewConsumption('milk', 999), throwsA(isA<InsufficientStockException>()));
    expect(db.productById('milk').totalRemaining, 10);
  });

  test('applying a consumption empties the earliest lot without deleting it', () {
    db.applyConsumption('milk', 6);
    final milk = db.productById('milk');
    expect(milk.totalRemaining, 4);
    expect(milk.lots, hasLength(2));
    expect(milk.lotsFefo.first.remainingQuantity, 0);
  });

  test('archive hides from the default list but keeps lots and price history', () {
    db.archive('milk');
    expect(db.productsFor('northside-main').map((p) => p.id), isNot(contains('milk')));

    final archived = db
        .productsFor('northside-main', includeArchived: true)
        .firstWhere((p) => p.id == 'milk');
    expect(archived.archived, isTrue);
    expect(archived.lots, isNotEmpty);
    expect(archived.latestUnitPrice, isNotNull);

    db.restore('milk');
    expect(db.productsFor('northside-main').map((p) => p.id), contains('milk'));
  });

  test('adding a lot lands on the product and moves its derived figures', () {
    final before = db.productById('milk').totalRemaining;
    db.addLot(Lot(
      id: 'new-lot',
      productId: 'milk',
      purchasedOn: DateTime(2026, 8, 19),
      expiresOn: DateTime(2026, 9, 5),
      unitPrice: 1.30,
      initialQuantity: 12,
      remainingQuantity: 12,
    ));
    expect(db.productById('milk').totalRemaining, before + 12);
    expect(db.productById('milk').latestUnitPrice, 1.30);
  });

  test('the seed carries the design fixtures, including undated goods', () {
    expect(db.stores.map((s) => s.name),
        containsAll(['Northside · Main', 'Northside · Depot', 'Riverside Kiosk']));
    expect(db.productById('sea-salt').nearestExpiry, isNull);
    expect(db.productById('sea-salt').hasStock, isTrue);
  });
}
