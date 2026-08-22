import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/media_repository.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final createStoreStateProvider =
    NotifierProvider<CreateStoreStateNotifier, CreateStoreState>(
      CreateStoreStateNotifier.new,
      isAutoDispose: true,
    );

class CreateStoreState extends BaseState with Equatable {
  const CreateStoreState({
    this.name = '',
    this.categoryCode,
    this.currency,
    this.address = '',
    this.url = '',
    this.logoUrl,
    this.isUploading = false,
    this.urlIsInvalid = false,
    this.categories = const [],
    this.currencies = const [],
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final String name;
  final String? categoryCode;
  /// Null until the currencies table has loaded and a row has been picked.
  /// Nothing can be submitted before then — the database wants a real id.
  final Currency? currency;
  final String address;
  final String url;
  final String? logoUrl;
  final bool isUploading;
  final bool urlIsInvalid;
  final List<StoreCategory> categories;
  final List<Currency> currencies;

  bool get canSubmit =>
      name.isNotBlank && categoryCode != null && currency != null && !isLoading && !isUploading;

  /// What the row shows. Falls back to the VND default so the field is never
  /// blank while the table is still loading.
  Currency get displayCurrency => currency ?? Currency.vnd;

  StoreCategory? get category {
    if (categoryCode == null) return null;
    for (final c in categories) {
      if (c.code == categoryCode) return c;
    }
    return null;
  }

  @override
  CreateStoreState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    String? name,
    String? categoryCode,
    Currency? currency,
    String? address,
    String? url,
    String? logoUrl,
    bool? isUploading,
    bool? urlIsInvalid,
    List<StoreCategory>? categories,
    List<Currency>? currencies,
  }) {
    return CreateStoreState(
      name: name ?? this.name,
      categoryCode: categoryCode ?? this.categoryCode,
      currency: currency ?? this.currency,
      address: address ?? this.address,
      url: url ?? this.url,
      logoUrl: logoUrl ?? this.logoUrl,
      isUploading: isUploading ?? this.isUploading,
      urlIsInvalid: urlIsInvalid ?? this.urlIsInvalid,
      categories: categories ?? this.categories,
      currencies: currencies ?? this.currencies,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    categoryCode,
    currency,
    address,
    url,
    logoUrl,
    isUploading,
    urlIsInvalid,
    categories,
    currencies,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class CreateStoreStateNotifier extends BaseStateNotifier<CreateStoreState> {
  late final StoreRepository _storeRepository;
  late final MediaRepository _mediaRepository;
  late final AuthRepository _authRepository;

  @override
  CreateStoreState createInitialState() {
    _storeRepository = ref.read(storeRepositoryProvider);
    _mediaRepository = ref.read(mediaRepositoryProvider);
    _authRepository = ref.read(authRepositoryProvider);
    return const CreateStoreState();
  }

  void updateName(String value) =>
      updateState(state.copyWith(name: value, status: StateLifeCycle.init));

  void updateCategory(String code) =>
      updateState(state.copyWith(categoryCode: code, status: StateLifeCycle.init));

  void updateCurrency(Currency value) => updateState(state.copyWith(currency: value));

  void updateAddress(String value) => updateState(state.copyWith(address: value));

  /// The invalid mark clears as soon as the user edits, so the error never
  /// sits there while it is being corrected.
  void updateUrl(String value) =>
      updateState(state.copyWith(url: value, urlIsInvalid: false));

  /// Loads both reference tables the form needs; neither is useful alone.
  Future<void> loadCategories() async {
    try {
      showLoading();
      final categories = await _storeRepository.categories();
      final currencies = await _storeRepository.currencies();
      if (!ref.mounted) return;
      showLoaded();
      updateState(
        state.copyWith(
          categories: categories,
          currencies: currencies,
          currency: state.currency ?? _defaultCurrency(currencies),
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  /// Prefers VND, which is what the column defaulted to before shops carried
  /// a currency id at all.
  Currency? _defaultCurrency(List<Currency> currencies) {
    if (currencies.isEmpty) return null;
    for (final c in currencies) {
      if (c.code == Currency.vnd.code) return c;
    }
    return currencies.first;
  }

  Future<void> pickedLogo({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      updateState(state.copyWith(isUploading: true, status: StateLifeCycle.init));
      final url = await _mediaRepository.uploadStoreLogo(
        bytes: bytes,
        fileExtension: fileExtension,
      );
      if (!ref.mounted) return;
      updateState(state.copyWith(logoUrl: url, isUploading: false));
    } on Object catch (e) {
      if (!ref.mounted) return;
      updateState(state.copyWith(isUploading: false));
      onError(e);
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) {
      showSnackError(
        msg: state.name.isNotBlank
            ? LocaleKeys.onboarding_store_categoryRequired
            : LocaleKeys.onboarding_store_nameRequired,
      );
      return;
    }

    // A blank link is fine; one that cannot be parsed is not.
    if (state.url.isNotBlank && normalisedUrlOrNull(state.url) == null) {
      updateState(state.copyWith(urlIsInvalid: true));
      return;
    }

    try {
      showLoading();
      final store = await _storeRepository.create(
        name: state.name,
        categoryCode: state.categoryCode!,
        currencyId: state.currency!.id,
        address: state.address,
        url: state.url,
        logoUrl: state.logoUrl,
      );
      await _rememberActiveStore(store.id);
      await _authRepository.completeOnboarding();
      if (!ref.mounted) return;
      showLoaded();
      router()?.goNamed(AppRoutes.dashboardName);
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }

  Future<void> _rememberActiveStore(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(OnboardingResolver.activeStoreKey, id);
    } on Object catch (e) {
      logger.w('Failed to persist the active store id', error: e);
    }
  }
}
