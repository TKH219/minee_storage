import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/media_repository.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final productFormStateProvider =
    NotifierProvider<ProductFormStateNotifier, ProductFormState>(
      ProductFormStateNotifier.new,
      isAutoDispose: true,
    );

class ProductFormState extends BaseState with Equatable {
  const ProductFormState({
    this.productId,
    this.name = '',
    this.unit = ProductUnit.piece,
    this.barcode = '',
    this.brand = '',
    this.category = '',
    this.notes = '',
    this.photoUrl,
    this.isUploading = false,
    this.categories = const [],
    this.barcodeConflictName,
    this.savedProductId,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  /// Null while creating; set once [ProductFormStateNotifier.loadForEdit] has run.
  final String? productId;
  final String name;
  final ProductUnit unit;
  final String barcode;
  final String brand;
  final String category;
  final String notes;
  final String? photoUrl;
  final bool isUploading;

  /// Every category value the caller has already used, for the autocomplete.
  final List<String> categories;

  /// The product already holding the entered barcode, if any. Named rather than
  /// flagged so the message can say which product it clashes with.
  final String? barcodeConflictName;

  /// Set once a save has landed, so the page knows to leave.
  final String? savedProductId;

  bool get isEditing => productId != null;

  /// A name is the only required field, per the design's own note.
  bool get canSubmit => name.isNotBlank && !isLoading && !isUploading;

  bool get canArchive => isEditing;

  /// Values already used that the typed text is a prefix of. An exact match
  /// suggests nothing — there is nothing left to complete.
  List<String> get categorySuggestions {
    final typed = category.trim().toLowerCase();
    if (typed.isEmpty) return const [];
    return categories
        .where((value) => value.toLowerCase() != typed)
        .where((value) => value.toLowerCase().contains(typed))
        .toList();
  }

  @override
  ProductFormState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    String? productId,
    String? name,
    ProductUnit? unit,
    String? barcode,
    String? brand,
    String? category,
    String? notes,
    String? photoUrl,
    bool? isUploading,
    List<String>? categories,
    String? barcodeConflictName,
    String? savedProductId,
    bool clearBarcodeConflict = false,
  }) {
    return ProductFormState(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      isUploading: isUploading ?? this.isUploading,
      categories: categories ?? this.categories,
      barcodeConflictName:
          clearBarcodeConflict ? null : (barcodeConflictName ?? this.barcodeConflictName),
      savedProductId: savedProductId ?? this.savedProductId,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    name,
    unit,
    barcode,
    brand,
    category,
    notes,
    photoUrl,
    isUploading,
    categories,
    barcodeConflictName,
    savedProductId,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ProductFormStateNotifier extends BaseStateNotifier<ProductFormState> {
  late final ProductRepository _repository;
  late final MediaRepository _media;
  String? _storeId;

  @override
  ProductFormState createInitialState() {
    _repository = ref.read(productRepositoryProvider);
    _media = ref.read(mediaRepositoryProvider);
    _storeId = ref.read(activeStoreProvider);
    return const ProductFormState();
  }

  void updateName(String value) =>
      updateState(state.copyWith(name: value, status: StateLifeCycle.init));

  void updateUnit(ProductUnit value) => updateState(state.copyWith(unit: value));

  /// The conflict mark clears as soon as the barcode is edited, so it never
  /// sits there while it is being corrected.
  void updateBarcode(String value) => updateState(
    state.copyWith(
      barcode: value,
      clearBarcodeConflict: true,
      status: StateLifeCycle.init,
    ),
  );

  void updateBrand(String value) => updateState(state.copyWith(brand: value));

  void updateCategory(String value) => updateState(state.copyWith(category: value));

  void updateNotes(String value) => updateState(state.copyWith(notes: value));

  Future<void> loadCategories() async {
    try {
      final categories = await _repository.getCategories();
      if (!ref.mounted) return;
      updateState(state.copyWith(categories: categories));
    } on Object catch (e) {
      // A missing suggestion list must not break the form it decorates.
      logger.e('Failed to load product categories', error: e);
    }
  }

  Future<void> loadForEdit(String id) async {
    final storeId = _storeId;
    if (storeId == null) return _refuseWithoutStore();

    try {
      showLoading();
      final product = await _repository.getProduct(id, storeId: storeId);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(
          status: StateLifeCycle.loaded,
          productId: product.id,
          name: product.name,
          unit: product.unit,
          barcode: product.barcode ?? '',
          brand: product.brand ?? '',
          category: product.category ?? '',
          notes: product.notes ?? '',
          photoUrl: product.photoUrl,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  Future<void> pickedPhoto({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      updateState(state.copyWith(isUploading: true, status: StateLifeCycle.init));
      final url = await _media.uploadProductPhoto(
        bytes: bytes,
        fileExtension: fileExtension,
      );
      if (!ref.mounted) return;
      updateState(state.copyWith(photoUrl: url, isUploading: false));
    } on Object catch (e) {
      if (!ref.mounted) return;
      updateState(state.copyWith(isUploading: false));
      onError(e);
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    final storeId = _storeId;
    if (storeId == null) return _refuseWithoutStore();

    // The barcode index spans archived rows, so a clash is checked here and
    // named rather than surfacing as a bare 409 from the database.
    if (await _barcodeIsTaken(storeId)) return;
    if (!ref.mounted) return;

    final draft = ProductDraft(
      name: state.name.trim(),
      unit: state.unit,
      barcode: _blankToNull(state.barcode),
      brand: _blankToNull(state.brand),
      category: _blankToNull(state.category),
      notes: _blankToNull(state.notes),
      photoUrl: state.photoUrl,
    );

    try {
      showLoading();
      final saved = state.isEditing
          ? await _repository.updateProduct(state.productId!, draft, storeId: storeId)
          : await _repository.createProduct(draft, storeId: storeId);
      if (!ref.mounted) return;
      updateState(
        state.copyWith(status: StateLifeCycle.loaded, savedProductId: saved.id),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  Future<void> archive() async {
    final storeId = _storeId;
    final id = state.productId;
    if (storeId == null || id == null) return;

    try {
      showLoading();
      await _repository.archiveProduct(id, storeId: storeId);
      if (!ref.mounted) return;
      updateState(state.copyWith(status: StateLifeCycle.loaded, savedProductId: id));
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  Future<bool> _barcodeIsTaken(String storeId) async {
    final barcode = _blankToNull(state.barcode);
    if (barcode == null) return false;

    try {
      final holder = await _repository.findByBarcode(barcode, storeId: storeId);
      if (holder == null || holder.id == state.productId) return false;
      if (!ref.mounted) return true;
      updateState(
        state.copyWith(
          status: StateLifeCycle.error,
          errorMessageKey: LocaleKeys.products_barcodeTaken,
          barcodeConflictName: holder.name,
        ),
      );
      return true;
    } on Object catch (e) {
      // A lookup that fails is not proof the barcode is free, but blocking the
      // save on it would strand the user; the database still has the last word.
      logger.w('Barcode pre-check failed', error: e);
      return false;
    }
  }

  void _refuseWithoutStore() {
    updateState(
      state.copyWith(
        status: StateLifeCycle.error,
        errorMessageKey: LocaleKeys.products_noActiveStore,
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
