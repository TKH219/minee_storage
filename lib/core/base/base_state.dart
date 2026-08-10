import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';
import 'package:mine_storage/shared/utils/logger.dart';

enum StateLifeCycle { init, loading, loaded, error }

/// Every feature state extends this, so [BasePageState] can drive the shared
/// loading overlay and error surface without knowing anything about the feature.
abstract class BaseState {
  const BaseState({this.status = StateLifeCycle.init, this.errorMessage});

  final StateLifeCycle status;

  /// Only meaningful while [isError] is true. It is deliberately not cleared on
  /// every transition, so `copyWith` stays a plain `??` merge with no sentinel.
  final String? errorMessage;

  bool get isInit => status == StateLifeCycle.init;

  bool get isLoading => status == StateLifeCycle.loading;

  bool get isLoaded => status == StateLifeCycle.loaded;

  bool get isError => status == StateLifeCycle.error;

  BaseState copyWith({StateLifeCycle? status, String? errorMessage});
}

abstract class BaseStateNotifier<T extends BaseState> extends AutoDisposeNotifier<T> {
  GoRouter? _router;

  /// Navigation entry point for notifiers. Prefer this over reaching for a
  /// `BuildContext`, which a notifier does not own.
  GoRouter? router() => _router;

  T createInitialState();

  @protected
  void updateState(T newState) {
    state = newState;
  }

  @override
  T build() {
    ref.onDispose(onDispose);
    _router = ref.read(routerProvider);
    return createInitialState();
  }

  Future<void> onDispose() async {}

  void showLoading() {
    updateState(state.copyWith(status: StateLifeCycle.loading) as T);
  }

  void showLoaded() {
    updateState(state.copyWith(status: StateLifeCycle.loaded) as T);
  }

  /// Parks the message on the state, then hands the error to `AppErrorHandler`,
  /// which owns every side effect the app takes about it.
  ///
  /// [present] suppresses the snack for this one call so a screen can render
  /// the error itself. It cannot suppress a purge or a redirect.
  void onError(Object error, {bool present = true}) {
    final exception = resolveException(error);
    updateState(
      state.copyWith(status: StateLifeCycle.error, errorMessage: exception.displayMessage) as T,
    );
    unawaited(ref.read(appErrorHandlerProvider).handle(exception, present: present));
    logger.e('Error: ${exception.displayMessage}', error: error);
  }

  /// [ErrorInterceptor] rejects with a `DioException` carrying the typed
  /// [AppException] in `.error`, so unwrap one level before classifying.
  @protected
  AppException resolveException(Object error) {
    final resolved = error is DioException ? (error.error ?? error) : error;

    if (resolved is AppException) return resolved;
    if (resolved is DioException) {
      return ServerException(message: resolved.message ?? 'An unknown network error occurred.');
    }
    return ServerException(message: 'An unknown error occurred: $resolved');
  }

  void showSnackError({required String msg}) => showErrorSnack(msg);

  void showBannerSuccess({required String title, String? subtitle}) {
    final context = snackbarKey.currentContext;
    if (context == null) return;

    final banner = MaterialBanner(
      backgroundColor: context.colors.green0,
      leading: Icon(Icons.check_circle_rounded, color: context.colors.green5),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textStyles.sansBodyBold.copyWith(
              color: context.colors.neutral9,
              fontSize: 14,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty)
            Text(
              subtitle,
              style: context.textStyles.sansBody.copyWith(color: context.colors.neutral9),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close_rounded, color: context.colors.green5),
          onPressed: () => snackbarKey.currentState?.clearMaterialBanners(),
        ),
      ],
    );

    snackbarKey.currentState
      ?..clearMaterialBanners()
      ..showMaterialBanner(banner);
  }
}
