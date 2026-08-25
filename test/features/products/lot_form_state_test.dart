import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/lot_form_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

ProductEntity product({ProductUnit unit = ProductUnit.kg}) => ProductEntity(
  id: 'p1',
  name: 'Whole Milk 1L',
  unit: unit,
  createdAt: DateTime.parse('2026-07-01'),
  updatedAt: DateTime.parse('2026-07-01'),
);

void main() {
  setUp(useLocale);

  ProviderContainer containerWith(_RecordingRepository repository) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
        activeStoreProvider.overrideWithValue('store-a'),
      ],
    );
    addTearDown(container.dispose);
    container.listen(lotFormStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  LotFormStateNotifier opened(ProviderContainer container, {ProductUnit unit = ProductUnit.kg}) {
    final notifier = container.read(lotFormStateProvider.notifier);
    notifier.open(product(unit: unit));
    return notifier;
  }

  group('the four validation rules', () {
    test('quantity must be above zero', () {
      final container = containerWith(_RecordingRepository());
      final notifier = opened(container)
        ..updateUnitPrice('1.00')
        ..updateQuantity('0');

      expect(container.read(lotFormStateProvider).quantityIsInvalid, isTrue);
      expect(container.read(lotFormStateProvider).canSubmit, isFalse);

      notifier.updateQuantity('3');
      expect(container.read(lotFormStateProvider).quantityIsInvalid, isFalse);
      expect(container.read(lotFormStateProvider).canSubmit, isTrue);
    });

    test('remaining cannot exceed what was bought', () {
      final container = containerWith(_RecordingRepository());
      final notifier = opened(container)
        ..updateUnitPrice('1.00')
        ..updateQuantity('12')
        ..updateRemaining('14');

      expect(container.read(lotFormStateProvider).remainingIsInvalid, isTrue);
      expect(container.read(lotFormStateProvider).canSubmit, isFalse);

      notifier.updateRemaining('12');
      expect(container.read(lotFormStateProvider).remainingIsInvalid, isFalse);
    });

    test('expiry must come after the purchase date', () {
      final container = containerWith(_RecordingRepository());
      final notifier = opened(container)
        ..updateUnitPrice('1.00')
        ..updateQuantity('5')
        ..updatePurchasedAt(DateTime.parse('2026-08-08'))
        ..updateExpiryDate(DateTime.parse('2026-08-02'));

      expect(container.read(lotFormStateProvider).expiryIsInvalid, isTrue);
      expect(container.read(lotFormStateProvider).canSubmit, isFalse);

      notifier.updateExpiryDate(DateTime.parse('2026-09-05'));
      expect(container.read(lotFormStateProvider).expiryIsInvalid, isFalse);
    });

    test('price cannot be negative', () {
      final container = containerWith(_RecordingRepository());
      final notifier = opened(container)
        ..updateQuantity('5')
        ..updateUnitPrice('-1');

      expect(container.read(lotFormStateProvider).priceIsInvalid, isTrue);
      expect(container.read(lotFormStateProvider).canSubmit, isFalse);

      notifier.updateUnitPrice('0');
      expect(container.read(lotFormStateProvider).priceIsInvalid, isFalse);
    });

    test('each rule fails independently of the others', () {
      final container = containerWith(_RecordingRepository());
      opened(container)
        ..updateQuantity('0')
        ..updateUnitPrice('1.00')
        ..updatePurchasedAt(DateTime.parse('2026-08-08'))
        ..updateExpiryDate(DateTime.parse('2026-09-05'));

      final state = container.read(lotFormStateProvider);
      expect(state.quantityIsInvalid, isTrue);
      expect(state.priceIsInvalid, isFalse);
      expect(state.expiryIsInvalid, isFalse);
      expect(state.remainingIsInvalid, isFalse);
    });
  });

  test('the live lot total is quantity times price, never stored', () {
    final container = containerWith(_RecordingRepository());
    opened(container)
      ..updateQuantity('12')
      ..updateUnitPrice('1.30');

    expect(container.read(lotFormStateProvider).lotTotal, Decimal.parse('15.60'));
  });

  test('a fractional quantity on a count unit is refused at input', () {
    final container = containerWith(_RecordingRepository());
    opened(container, unit: ProductUnit.piece)
      ..updateUnitPrice('1.00')
      ..updateQuantity('2.5');

    expect(container.read(lotFormStateProvider).quantityIsInvalid, isTrue);
  });

  group('the deviations', () {
    test('the store defaults to the active one and can be changed', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository);
      final notifier = opened(container);

      expect(container.read(lotFormStateProvider).storeId, 'store-a');

      notifier
        ..updateStore('store-b')
        ..updateQuantity('4')
        ..updateUnitPrice('2.00');
      await notifier.submit();

      expect(repository.lastDraft?.storeId, 'store-b');
    });

    test('storage location rides on the lot, not the product', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository);
      final notifier = opened(container)
        ..updateQuantity('4')
        ..updateUnitPrice('2.00')
        ..updateStorageLocation('Cold room A');

      await notifier.submit();

      expect(repository.lastDraft?.storageLocation, 'Cold room A');
    });
  });

  test('an undated lot submits no expiry at all', () async {
    final repository = _RecordingRepository();
    final container = containerWith(repository);
    final notifier = opened(container)
      ..updateQuantity('4')
      ..updateUnitPrice('2.00')
      ..updateExpiryDate(null);

    await notifier.submit();

    expect(repository.lastDraft?.expiryDate, isNull);
  });

  test('an invalid form sends nothing', () async {
    final repository = _RecordingRepository();
    final container = containerWith(repository);
    final notifier = opened(container)..updateQuantity('0');

    await notifier.submit();

    expect(repository.addCalls, 0);
  });
}

class _RecordingRepository extends FakeProductRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  int addCalls = 0;
  BatchDraft? lastDraft;

  @override
  Future<ProductEntity> addBatch(String productId, BatchDraft draft) async {
    addCalls++;
    lastDraft = draft;
    return product();
  }
}
