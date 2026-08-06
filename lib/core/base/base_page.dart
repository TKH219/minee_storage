import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/base/base_view.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';

/// A full screen pushed by the router.
abstract class BasePage extends BaseView {
  const BasePage({super.key});
}

abstract class BasePageState<
  T extends BasePage,
  S extends BaseState,
  N extends BaseStateNotifier<dynamic>
>
    extends BaseViewState<T, S, N> {
  /// Whether the back gesture / system back button may leave this page.
  /// Set false to trap the user (e.g. mid-flow screens).
  bool canPopPage = true;

  Widget buildPageContent(BuildContext context);

  /// The loading overlay and the unfocus gesture are already applied by
  /// [BaseViewState.build]; this only adds the page-level pop guard.
  @override
  Widget buildContent(BuildContext context) {
    return PopScope(
      canPop: canPopPage,
      child: buildPageContent(context),
    );
  }

  Widget loadingWidget() {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      body: const Center(child: LoadingCircle()),
    );
  }
}
