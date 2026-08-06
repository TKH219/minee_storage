import 'dart:async';

import 'package:dio/dio.dart';

import 'package:mine_storage/core/constants.dart';
import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/data/data_sources/local/user_local_data_source.dart';
import 'package:mine_storage/data/models/response/auth/token_refreshed_model.dart';
import 'package:mine_storage/shared/utils/logger.dart';

/// Refreshes an expired access token and replays the failed request.
///
/// Extends [QueuedInterceptorsWrapper] so concurrent 401s queue behind a single
/// refresh instead of firing N refresh calls and invalidating each other.
class RefreshTokenInterceptor extends QueuedInterceptorsWrapper {
  RefreshTokenInterceptor({
    required this.dio,
    required this.apiUrl,
    required this.userLocalDataSource,
    required this.onSessionExpired,
  });

  final Dio dio;
  final String apiUrl;
  final UserLocalDataSource userLocalDataSource;

  /// Called after the refresh has definitively failed and local auth has been
  /// cleared. Wired to a router redirect in `providers.dart`.
  final Future<void> Function() onSessionExpired;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isAuthFailure(err)) {
      handler.next(err);
      return;
    }

    if (!_isRefreshing) {
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          _refreshCompleter?.complete();
        } else {
          _refreshCompleter?.completeError(err);
        }
      } on Object catch (e) {
        _refreshCompleter?.completeError(e);
      } finally {
        _isRefreshing = false;
      }
    }

    try {
      await _refreshCompleter?.future;
      final auth = await userLocalDataSource.getAppAuth();
      if (auth == null) {
        handler.next(err);
        return;
      }
      err.requestOptions.headers['Authorization'] = auth.accessTokenHeader;
      final response = await dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on Object catch (_) {
      // Let ErrorInterceptor map the original failure into an AppException.
      handler.next(err);
    }
  }

  bool _isAuthFailure(DioException err) {
    if (err.response?.statusCode == 401) return true;
    final data = err.response?.data;
    if (data is! Map) return false;
    return const {
      ServerErrorCodes.unauthorised,
      ServerErrorCodes.tokenExpired,
      ServerErrorCodes.tokenInvalid,
    }.contains(data['code']);
  }

  /// Uses a bare [Dio] so the refresh call cannot recurse back into this
  /// interceptor when it fails.
  Future<bool> _refreshToken() async {
    try {
      final auth = await userLocalDataSource.getAppAuth();
      if (auth == null || auth.refreshToken.isEmpty) {
        await _expireSession();
        return false;
      }

      final response = await Dio(
        BaseOptions(
          baseUrl: apiUrl,
          connectTimeout: Constants.networkTimeout,
          sendTimeout: Constants.networkTimeout,
          receiveTimeout: Constants.networkTimeout,
        ),
      ).post<Map<String, dynamic>>(
        '/auth/refresh-token',
        data: {'refreshToken': auth.refreshToken, 'userId': auth.userId},
      );

      final payload = response.data?['data'];
      if (response.statusCode != 200 || payload is! Map<String, dynamic>) {
        await _expireSession();
        return false;
      }

      final refreshed = TokenRefreshedModel.fromJson(payload);
      final updated = await userLocalDataSource.updateAppAuth(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
      );

      if (updated == null) {
        await _expireSession();
        return false;
      }
      return true;
    } on Object catch (e) {
      logger.e('Cannot refresh token', error: e);
      await _expireSession();
      return false;
    }
  }

  Future<void> _expireSession() async {
    await userLocalDataSource.logout();
    await onSessionExpired();
  }
}
