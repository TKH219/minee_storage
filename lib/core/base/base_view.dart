import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/shared/ui/loading_circle.dart';

/// A composable piece of UI backed by a [BaseStateNotifier].
///
/// Use [BaseView] for a widget embedded inside another screen; use `BasePage`
/// for something the router pushes as a whole screen.
abstract class BaseView extends ConsumerStatefulWidget {
  const BaseView({super.key});
}

abstract class BaseViewState<
  T extends BaseView,
  S extends BaseState,
  N extends BaseStateNotifier<dynamic>
>
    extends ConsumerState<T> {
  late S currentState;
  late N notifier;

  /// Set false when the view renders its own loading treatment and should not
  /// get the shared full-bleed overlay.
  bool allowToShowLoading = true;

  Widget buildContent(BuildContext context);

  /// Assign [currentState] here, e.g. `currentState = ref.watch(homeStateProvider)`.
  void setCurrentState();

  /// Assign [notifier] here, e.g. `notifier = ref.read(homeStateProvider.notifier)`.
  void setNotifier();

  /// Runs once after the first frame — safe place to kick off initial loads.
  void initDataFromConstructor() {}

  @override
  void initState() {
    super.initState();
    setNotifier();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initDataFromConstructor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    setCurrentState();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          buildContent(context),
          if (currentState.isLoading && allowToShowLoading)
            const Positioned.fill(child: LoadingCircle()),
        ],
      ),
    );
  }
}
