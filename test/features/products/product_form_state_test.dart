import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/form/states/product_form_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_media_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  ProviderContainer containerWith({
    FakeProductRepository? repository,
    FakeMediaRepository? media,
    String? activeStore = 'store-a',
  }) {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          repository ?? FakeProductRepository(latency: Duration.zero),
        ),
        mediaRepositoryProvider.overrideWithValue(media ?? FakeMediaRepository()),
        activeStoreProvider.overrideWithValue(activeStore),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productFormStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  group('save gating', () {
    test('a blank name cannot be submitted', () {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);

      expect(container.read(productFormStateProvider).canSubmit, isFalse);

      notifier.updateName('   ');
      expect(container.read(productFormStateProvider).canSubmit, isFalse);

      notifier.updateName('Olive oil');
      expect(container.read(productFormStateProvider).canSubmit, isTrue);
    });

    test('a name alone is enough — every other field is optional', () {
      final container = containerWith();

      container.read(productFormStateProvider.notifier).updateName('Rice');

      expect(container.read(productFormStateProvider).canSubmit, isTrue);
    });
  });

  group('unit', () {
    test('defaults to piece', () {
      final container = containerWith();

      expect(container.read(productFormStateProvider).unit, ProductUnit.piece);
    });

    test('is carried into the draft that is saved', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository: repository);
      final notifier = container.read(productFormStateProvider.notifier);

      notifier
        ..updateName('Olive oil')
        ..updateUnit(ProductUnit.litre);
      await notifier.submit();

      expect(repository.lastDraft?.unit, ProductUnit.litre);
      expect(repository.lastStoreId, 'store-a');
    });
  });

  group('category autocomplete', () {
    test('offers only values the caller has already used', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);

      await notifier.loadCategories();

      final categories = container.read(productFormStateProvider).categories;
      expect(categories, contains('Pantry'));
      expect(categories, isNot(contains('Nonexistent')));
    });

    test('narrows the suggestions as the field is typed', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);
      await notifier.loadCategories();

      notifier.updateCategory('pan');

      expect(
        container.read(productFormStateProvider).categorySuggestions,
        ['Pantry'],
      );
    });

    test('suggests nothing once the field exactly matches', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);
      await notifier.loadCategories();

      notifier.updateCategory('Pantry');

      expect(container.read(productFormStateProvider).categorySuggestions, isEmpty);
    });
  });

  group('edit mode', () {
    test('prefills every field from the product', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);

      await notifier.loadForEdit('p1');

      final state = container.read(productFormStateProvider);
      expect(state.isEditing, isTrue);
      expect(state.name, 'Olive oil 1L');
      expect(state.barcode, '8934567890123');
      expect(state.brand, 'Basso');
      expect(state.category, 'Pantry');
      expect(state.notes, 'Cold pressed');
      expect(state.unit, ProductUnit.litre);
    });

    test('a create has nothing to archive; an edit does', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);

      expect(container.read(productFormStateProvider).canArchive, isFalse);

      await notifier.loadForEdit('p1');

      expect(container.read(productFormStateProvider).canArchive, isTrue);
    });
  });

  group('barcode conflict', () {
    test('a barcode already held by another product is refused before saving', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository: repository);
      final notifier = container.read(productFormStateProvider.notifier);

      notifier
        ..updateName('Another oil')
        ..updateBarcode('8934567890123');
      await notifier.submit();

      final state = container.read(productFormStateProvider);
      expect(state.barcodeConflictName, 'Olive oil 1L');
      expect(state.errorMessageKey, LocaleKeys.products_barcodeTaken);
      expect(repository.lastDraft, isNull, reason: 'nothing should have been sent');
    });

    test('an archived holder still blocks the barcode', () async {
      final repository = _ArchivedHolderRepository();
      final container = containerWith(repository: repository);
      final notifier = container.read(productFormStateProvider.notifier);

      notifier
        ..updateName('Another oil')
        ..updateBarcode('ARCHIVED-1');
      await notifier.submit();

      expect(
        container.read(productFormStateProvider).barcodeConflictName,
        'Archived holder',
      );
      expect(repository.lastDraft, isNull);
    });

    test('the same product keeping its own barcode is not a conflict', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository: repository);
      final notifier = container.read(productFormStateProvider.notifier);

      await notifier.loadForEdit('p1');
      notifier.updateName('Olive oil 1L renamed');
      await notifier.submit();

      expect(container.read(productFormStateProvider).barcodeConflictName, isNull);
      expect(repository.lastDraft?.name, 'Olive oil 1L renamed');
    });

    test('editing clears a conflict mark rather than leaving it stale', () async {
      final container = containerWith();
      final notifier = container.read(productFormStateProvider.notifier);

      notifier
        ..updateName('Another oil')
        ..updateBarcode('8934567890123');
      await notifier.submit();
      expect(container.read(productFormStateProvider).barcodeConflictName, isNotNull);

      notifier.updateBarcode('8934567890124');

      expect(container.read(productFormStateProvider).barcodeConflictName, isNull);
    });
  });

  group('photo', () {
    test('an uploaded photo lands on the draft', () async {
      final repository = _RecordingRepository();
      final media = FakeMediaRepository(returnedUrl: 'https://cdn.example/p.png');
      final container = containerWith(repository: repository, media: media);
      final notifier = container.read(productFormStateProvider.notifier);

      notifier.updateName('Olive oil');
      await notifier.pickedPhoto(bytes: Uint8List(3), fileExtension: 'png');
      await notifier.submit();

      expect(media.calls, contains('uploadProductPhoto'));
      expect(repository.lastDraft?.photoUrl, 'https://cdn.example/p.png');
    });

    test('a failed upload leaves the form usable rather than stuck uploading', () async {
      final media = FakeMediaRepository(error: const NetworkException(message: 'offline'));
      final container = containerWith(media: media);
      final notifier = container.read(productFormStateProvider.notifier);

      await notifier.pickedPhoto(bytes: Uint8List(3), fileExtension: 'png');

      final state = container.read(productFormStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.photoUrl, isNull);
    });
  });

  group('without an active store', () {
    test('refuses to save rather than filing stock into a guessed shop', () async {
      final repository = _RecordingRepository();
      final container = containerWith(repository: repository, activeStore: null);
      final notifier = container.read(productFormStateProvider.notifier);

      notifier.updateName('Olive oil');
      await notifier.submit();

      expect(
        container.read(productFormStateProvider).errorMessageKey,
        LocaleKeys.products_noActiveStore,
      );
      expect(repository.lastDraft, isNull);
    });
  });
}

class _RecordingRepository extends FakeProductRepository {
  _RecordingRepository() : super(latency: Duration.zero);

  ProductDraft? lastDraft;
  String? lastStoreId;

  @override
  Future<ProductEntity> createProduct(
    ProductDraft draft, {
    required String storeId,
  }) {
    lastDraft = draft;
    lastStoreId = storeId;
    return super.createProduct(draft, storeId: storeId);
  }

  @override
  Future<ProductEntity> updateProduct(
    String id,
    ProductDraft draft, {
    required String storeId,
  }) {
    lastDraft = draft;
    lastStoreId = storeId;
    return super.updateProduct(id, draft, storeId: storeId);
  }
}

/// The barcode index spans archived rows, so an archived product still holds
/// its barcode and the form has to say so before the server rejects the write.
class _ArchivedHolderRepository extends _RecordingRepository {
  @override
  Future<ProductEntity?> findByBarcode(String barcode, {required String storeId}) async {
    if (barcode != 'ARCHIVED-1') return null;
    return ProductEntity(
      id: 'archived-1',
      name: 'Archived holder',
      barcode: barcode,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      deletedAt: DateTime(2026, 2, 1),
      batches: [
        ProductBatchEntity(
          id: 'b0',
          productId: 'archived-1',
          storeId: storeId,
          batchCode: '#B-0001',
          purchasedAt: DateTime(2026, 1, 1),
          unitPrice: Decimal.one,
          initialQuantity: Decimal.one,
          remainingQuantity: Decimal.zero,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ],
    );
  }
}
