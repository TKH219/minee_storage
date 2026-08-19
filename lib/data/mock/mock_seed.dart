import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';
import 'package:mine_storage/domain/entities/store.dart';

typedef MockSeed = ({List<Store> stores, List<Product> products});

const _mainStore = 'northside-main';

MockSeed mockSeed() {
  Lot lotOf(
    String id,
    String productId, {
    required DateTime purchasedOn,
    DateTime? expiresOn,
    required double unitPrice,
    required double initial,
    double? remaining,
  }) =>
      Lot(
        id: id,
        productId: productId,
        purchasedOn: purchasedOn,
        expiresOn: expiresOn,
        unitPrice: unitPrice,
        initialQuantity: initial,
        remainingQuantity: remaining ?? initial,
      );

  final products = <Product>[
    Product(
      id: 'milk',
      storeId: _mainStore,
      name: 'Whole Milk 1L',
      barcode: '5012345678900',
      brand: 'Dairyland',
      category: 'Dairy',
      location: 'Cold room A',
      lots: [
        lotOf('milk-1', 'milk',
            purchasedOn: DateTime(2026, 8, 8),
            expiresOn: DateTime(2026, 8, 22),
            unitPrice: 1.10,
            initial: 12,
            remaining: 2),
        lotOf('milk-2', 'milk',
            purchasedOn: DateTime(2026, 8, 15),
            expiresOn: DateTime(2026, 9, 12),
            unitPrice: 1.25,
            initial: 10,
            remaining: 8),
      ],
    ),
    Product(
      id: 'rice',
      storeId: _mainStore,
      name: 'Basmati Rice 5kg',
      brand: 'Golden Fields',
      category: 'Dry goods',
      location: 'Dry shelf 3',
      lots: [
        lotOf('rice-1', 'rice',
            purchasedOn: DateTime(2026, 6, 2),
            expiresOn: DateTime(2026, 11, 3),
            unitPrice: 8.90,
            initial: 24),
      ],
    ),
    Product(
      id: 'olive-oil',
      storeId: _mainStore,
      name: 'Olive Oil 750ml',
      brand: 'Terra Verde',
      category: 'Dry goods',
      location: 'Dry shelf 1',
      lots: [
        lotOf('olive-oil-1', 'olive-oil',
            purchasedOn: DateTime(2026, 5, 12),
            expiresOn: DateTime(2026, 9, 12),
            unitPrice: 11.50,
            initial: 9),
      ],
    ),
    Product(
      id: 'chicken',
      storeId: _mainStore,
      name: 'Chicken Breast 1kg',
      category: 'Frozen',
      location: 'Freezer 2',
      lots: [
        lotOf('chicken-1', 'chicken',
            purchasedOn: DateTime(2026, 8, 12),
            expiresOn: DateTime(2026, 8, 28),
            unitPrice: 6.75,
            initial: 4.5),
      ],
    ),
    Product(
      id: 'yoghurt',
      storeId: _mainStore,
      name: 'Greek Yoghurt 500g',
      brand: 'Hellenic',
      category: 'Dairy',
      location: 'Cold room A',
      lots: [
        lotOf('yoghurt-1', 'yoghurt',
            purchasedOn: DateTime(2026, 7, 30),
            expiresOn: DateTime(2026, 8, 14),
            unitPrice: 2.40,
            initial: 6),
      ],
    ),
    Product(
      id: 'cheddar',
      storeId: _mainStore,
      name: 'Cheddar Block 400g',
      category: 'Dairy',
      location: 'Cold room A',
      lots: [
        lotOf('cheddar-1', 'cheddar',
            purchasedOn: DateTime(2026, 6, 20),
            expiresOn: DateTime(2026, 8, 1),
            unitPrice: 4.15,
            initial: 5,
            remaining: 0),
      ],
    ),
    Product(
      id: 'rye-crackers',
      storeId: _mainStore,
      name: 'Rye Crackers 200g',
      category: 'Dry goods',
      archived: true,
      lots: [
        lotOf('rye-crackers-1', 'rye-crackers',
            purchasedOn: DateTime(2026, 7, 2),
            expiresOn: DateTime(2026, 12, 18),
            unitPrice: 2.05,
            initial: 10,
            remaining: 3),
      ],
    ),
    Product(
      id: 'sea-salt',
      storeId: _mainStore,
      name: 'Sea Salt 1kg',
      category: 'Dry goods',
      lots: [
        lotOf('sea-salt-1', 'sea-salt',
            purchasedOn: DateTime(2026, 3, 14), unitPrice: 2.05, initial: 21),
      ],
    ),
    Product(
      id: 'rice-vinegar',
      storeId: _mainStore,
      name: 'Rice Vinegar 500ml',
      category: 'Dry goods',
      lots: [
        lotOf('rice-vinegar-1', 'rice-vinegar',
            purchasedOn: DateTime(2026, 4, 2), unitPrice: 2.20, initial: 14),
      ],
    ),
  ];

  final stores = <Store>[
    const Store(
        id: _mainStore,
        name: 'Northside · Main',
        currencyCode: 'USD',
        productCount: 128,
        role: StoreRole.owner),
    const Store(
        id: 'northside-depot',
        name: 'Northside · Depot',
        currencyCode: 'USD',
        productCount: 64,
        role: StoreRole.manager),
    const Store(
        id: 'riverside-kiosk',
        name: 'Riverside Kiosk',
        currencyCode: 'VND',
        productCount: 41,
        role: StoreRole.staff),
  ];

  return (stores: stores, products: products);
}
